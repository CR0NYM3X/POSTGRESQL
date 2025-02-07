### **1. Comandos Básicos Útiles**
#### **Capturar tráfico en una interfaz específica**
```bash
sudo tcpdump -i eth0
```
- **`-i`**: Especifica la interfaz (ej: `eth0`, `any` para todas).

#### **Evitar resolución DNS (mejor rendimiento)**
```bash
sudo tcpdump -n
```

#### **Guardar captura en un archivo `.pcap`**
```bash
sudo tcpdump -w trafico.pcap
```

#### **Leer un archivo `.pcap`**
```bash
tcpdump -r trafico.pcap
```

---

### **2. Filtros Específicos para Enfoque Profesional**
#### **Filtrar por protocolo**
```bash
sudo tcpdump icmp # Solo tráfico ICMP (pings)
sudo tcpdump tcp # Solo TCP
sudo tcpdump udp port 53 # DNS (puerto 53)
```

#### **Filtrar por IP y puerto**
```bash
sudo tcpdump host 192.168.1.100 # Tráfico desde/hacia una IP
sudo tcpdump src 10.0.0.5 and dst port 80 # Origen 10.0.0.5 y destino HTTP
sudo tcpdump net 192.168.1.0/24 # Red completa
```

#### **Filtrar por flags TCP (ej: SYN, ACK)**
```bash
sudo tcpdump 'tcp[tcpflags] & (tcp-syn|tcp-ack) != 0' # Paquetes SYN/ACK
sudo tcpdump 'tcp[13] = 2' # Solo SYN (código 2 en byte 13)
```

---

### **3. Análisis de Contenido (Deep Inspection)**
#### **Mostrar paquetes en ASCII y HEX**
```bash
sudo tcpdump -A -X # Muestra contenido en ASCII y hexadecimal
```

#### **Buscar palabras clave en el payload**
```bash
sudo tcpdump -A | grep "password" # Filtra tráfico con la palabra "password"
```

#### **Capturar cookies HTTP**
```bash
sudo tcpdump -A -s0 'port 80 and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420' | grep "Cookie:"
```

---

### **4. Escenarios Profesionales con Ejemplos**
#### **Detectar escaneos de puertos**
```bash
sudo tcpdump 'tcp[tcpflags] == tcp-syn and dst port 22' # Escaneo SYN a SSH
```

#### **Analizar tráfico HTTP (métodos GET/POST)**
```bash
sudo tcpdump -A -s0 'port 80 and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420' # Captura GET requests
sudo tcpdump -A -s0 'port 80 and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504F5354' # Captura POST requests
```

#### **Monitorear conexiones SSH**
```bash
sudo tcpdump -nnvX 'port 22 and (tcp-syn|tcp-ack)!=0'
```

#### **Identificar tráfico malicioso (ej: ataques DDoS)**
```bash
sudo tcpdump -nn 'dst net 192.168.1.0/24 and icmp' # ICMP Flood hacia tu red
```

---

### **5. Optimización y Manejo de Grandes Capturas**
#### **Limitar el tamaño de captura**
```bash
sudo tcpdump -C 100 -W 10 -w trafico.pcap # Crea archivos de 100MB, máximo 10 archivos
```

#### **Capturar solo los primeros bytes (útil para headers)**
```bash
sudo tcpdump -s 64 # Captura primeros 64 bytes de cada paquete
```

#### **Filtrar por tamaño de paquete**
```bash
sudo tcpdump 'greater 1000' # Paquetes mayores a 1000 bytes
```

---

### **6. Combinar con Herramientas Externas**
#### **Usar `grep`, `awk` o `Wireshark`**
```bash
tcpdump -r trafico.pcap | awk '/HTTP/ {print $0}' # Filtrar HTTP con awk
```
- **Wireshark**: Abre el `.pcap` para análisis gráfico:
  ```bash
  wireshark trafico.pcap
  ```

---

### **7. Consejos Profesionales**
- **Filtros BPF (Berkeley Packet Filter)**: Usa sintaxis avanzada para granularidad:
  ```bash
  sudo tcpdump 'src 192.168.1.5 and (dst port 443 or 80)'
  ```
- **Evita capturar todo el tráfico**: Siempre usa filtros para reducir ruido.
- **Privacidad**: No captures tráfico sensible sin autorización (ej: contraseñas, cookies).
- **Documentación oficial**: 
  ```bash
  man tcpdump # Consulta opciones avanzadas
  ```

---

### **Ejemplo Avanzado: Analizar Handshake TCP**
```bash
sudo tcpdump -nn -S 'tcp[tcpflags] & (tcp-syn|tcp-ack) != 0 and port 80'
```
- **Salida**:
  ```
  10:20:30.123 IP 192.168.1.100.54321 > 104.18.25.35.80: Flags [S], seq 123456789
  10:20:30.456 IP 104.18.25.35.80 > 192.168.1.100.54321: Flags [S.], seq 987654321, ack 123456790
  ```
  - `[S]`: SYN (inicio de conexión).
  - `[S.]`: SYN-ACK (respuesta del servidor).



### **Ejemplos prácticos:**

#### 1. **Capturar tráfico TCP en el puerto 5416**:
   ```bash
   sudo tcpdump -i any -nn 'host 192.168.1.100 && tcp port 5416'
   ```

#### 2. **Capturar tráfico UDP en el puerto 5416**:
   ```bash
   sudo tcpdump -i any -nn 'host 10.0.0.5 && udp port 5416'
   ```

#### 3. **Guardar captura en un archivo `.pcap`** (para análisis en Wireshark):
   ```bash
   sudo tcpdump -i any -nn 'host 192.168.1.100 and port 5416' -w captura.pcap
   ```

#### 4. **Mostrar contenido en ASCII** (útil para ver texto plano):
   ```bash
   sudo tcpdump -i any -nnA 'host 192.168.1.100 and port 5416'
   ```
   

---

**Dominarás tcpdump cuando**:
- Sepas filtrar tráfico específico en segundos.
- Identifiques rápidamente patrones sospechosos (ej: SYN floods).
- Combines filtros BPF con herramientas como Wireshark para análisis forense.
