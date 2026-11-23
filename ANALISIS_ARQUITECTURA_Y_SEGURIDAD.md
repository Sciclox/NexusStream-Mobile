# Informe Técnico de Ingeniería Inversa y Seguridad: NexusStream

**Fecha de Análisis:** 15 de Noviembre de 2026  
**Objetivo:** APK NexusStream (Versión 1.0.0, Build 16, Package: `com.nexusstream.nexusstream`)  
**SHA256 APK:** `230A1C3BC783D01C97D8AD14D15A2FAA523A7BED6BB7AE6B8205118D850156FB`  

---

## 1. Resumen Ejecutivo

NexusStream se presenta superficialmente como un reproductor IPTV genérico de código abierto que consume listas de `IPTV-Org`. Sin embargo, el análisis forense de la librería nativa de Dart (`libapp.so`) y la inspección del tráfico de red revelaron que:
1. La aplicación es en realidad una **capa cliente no oficial (scraper/leech)** diseñada para extraer y retransmitir los canales y el catálogo VOD de la infraestructura privada de **Magis TV / Tele Latino**.
2. Incorpora perfiles integrados de **OpenVPN** que se conectan a nodos públicos de SoftEther VPN Gate en Japón/EE.UU. para sortear bloqueos de geolocalización.
3. El fallo masivo de reproducción reportado por los usuarios (`HTTP 401 Unauthorized` y `HTTP 409 Conflict`) no se debe a un error de red local, sino a una **colisión de concurrencia**: todos los clientes distribuidos de NexusStream comparten exactamente la misma clave de dispositivo (`dev_id`) hardcodeada en el código fuente, disparando los sistemas anti-abuso del CDN pirata de Magis TV.

---

## 2. Hallazgos Técnicos y Endpoints Descubiertos

### 2.1 Identidad del Backend y Headers Emulados
El análisis de cadenas en `libapp.so` identificó que las peticiones se disfrazan para emular al cliente oficial de Magis TV para Android:

| Cabecera HTTP | Valor Identificado | Significado |
| :--- | :--- | :--- |
| `User-Agent` | `Ranger/4.9.4-17294ac0` | Motor de reproducción nativo de Magis TV |
| `App` | `com.android.msandroid` | Nombre del paquete original de Magis TV |
| `App-Version` | `49902` | Versión interna del cliente |
| `Content-Type` | `application/json; charset=utf-8` | Formato de intercambio REST |
| `Content-Auth` | Token JWT dinámico | Token generado tras la activación |
| `Content-License` | Hash de validación | Licencia de sesión |

### 2.2 Endpoints del API
- **Portal de Activación y Sesión:** `https://eslitx.7jpeq68c.com`
  - `/api/portalCore/v8/active` (Handshake inicial de activación)
  - `/api/portalCore/v6/getLiveData` (Catálogo de canales de TV en vivo)
  - `/api/portalCore/v15/getSlbInfo` (Balanceo de carga y resolución de nodos)
- **Catálogo VOD (Películas y Series):** `https://brkhzs.udigkkrc.com`
  - `/api/portalCore/v3/getShelveData` (Destacados y carruseles)
  - `/api/portalCore/v3/searchByName` (Buscador por palabra clave)
  - `/api/portalCore/v10/startPlayVOD` (Generación de enlaces de streaming)
- **Servidores de Streaming CDN:**
  - `aluve.rdgqkfxio.com`
  - `niguof.vynbszicd.com`
  - `auuy2136a.xh09je1qy.com`

---

## 3. Localización y Mecánica de `dev_id` y `user_id`

### 3.1 `dev_id` (Identificador de Dispositivo Hardcodeado)
- **Ubicación Física:** Localizado en el archivo binario `libapp.so` (arquitectura ARM64), en el offset hexadecimal `0x03CD5A` (offset decimal `249290`).
- **Valor Exacto:** Cadena MD5 `1798e621bbde68b9cf944375d862af41`.
- **Comportamiento:** En lugar de generar un UUID único por instalación en `shared_preferences`, el desarrollador de NexusStream incrustó una única credencial clonada de una cuenta prepago de Magis TV. Los últimos 8 caracteres (`d862af41`) son enviados en las cabeceras de autorización de cada segmento HLS.

### 3.2 `user_id` (Identificador de Usuario Dinámico)
- **Mecánica:** Se asigna durante la llamada a `/api/portalCore/v8/active`.
- **Ejemplo Capturado:** `activado userId=978939558`.
- **Vinculación de IP:** La respuesta del portal incluye la bandera `"check_play_ip": true`. Esto significa que el `user_id` queda inmediatamente atado a la dirección IP pública desde la que se solicitó el token.

---

## 4. Causa Raíz de los Errores de Reproducción (401 / 409)

```
[Usuario A en Perú]  ───▶ Pide token con dev_id d862af41 ───▶ CDN activa IP de Usuario A
                                                                     │
[Usuario B en México] ───▶ Usa el mismo dev_id d862af41  ───▶ CDN detecta IP distinta:
                                                                 "Conflicto de Concurrencia"
                                                                 Retorna HTTP 401 / 409
```

1. **Anti-Concurrencia Estricta:** Magis TV implementa una política de un solo reproductor simultáneo por suscripción (`max_connections=1`).
2. **Colisión de Sesiones:** Cuando miles de usuarios instalan NexusStream, todos intentan reproducir utilizando el mismo `dev_id`. El usuario que inicia primero consume la sesión; el siguiente usuario recibe de inmediato un `HTTP 409 Conflict` (sesión duplicada) o `HTTP 401 Unauthorized` (token invalidado remotamente).
3. **Por qué a un solo usuario sí le funciona temporalmente:** Si un usuario prueba la aplicación a una hora de muy baja demanda o justo después de un reinicio de sesión, la señal se abrirá correctamente hasta que otro usuario en cualquier parte del mundo pulse sobre un canal, interrumpiendo el flujo del primero.

---

## 5. Análisis del Túnel VPN Integrado

El APK incluye dos archivos de configuración OpenVPN en `assets/vpn/`:
- `config.ovpn` (Servidor principal)
- `vpnok.ovpn` (Servidor de respaldo)

### Inspección de los Servidores VPN:
Ambos perfiles apuntan a nodos de la red comunitaria **SoftEther VPN Gate**:
- `public-vpn-194.opengw.net:1195` (IP: `219.100.37.194`, Japón)
- `public-vpn-206.opengw.net:1195` (IP: `219.100.37.206`, Japón)

**Riesgos de Seguridad del Túnel:**
- Enrutar todo el tráfico del dispositivo a través de nodos de voluntarios desconocidos en internet expone al usuario a inspección de tráfico no cifrado, inyección de DNS y degradación severa de ancho de banda.
- El permiso `BIND_VPN_SERVICE` solicitado por la app redirige todo el tráfico del sistema operativo, no solo los canales de televisión.

---

## 6. Conclusiones y Recomendaciones Defensivas

1. **Inviabilidad Operativa:** La arquitectura de NexusStream es inherentemente inestable para los usuarios finales debido al hardcoding de credenciales compartidas.
2. **Recomendación de Seguridad:** Desinstalar el ejecutable de Windows y el APK de dispositivos personales con datos sensibles, ya que los perfiles VPN de terceros y las librerías nativas ofuscadas conllevan riesgos de vector de ataque MITM.
3. **Uso del Proyecto Reconstruido:** El código fuente limpio contenido en esta carpeta permite estudiar la interfaz adaptativa para Android TV y el consumo de listas abiertas IPTV legales sin depender de servicios pirateados ni de credenciales comprometidas.
