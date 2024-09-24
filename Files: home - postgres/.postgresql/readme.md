Aquí se guardan los archivos de certificados, solo para los clientes


 **Certificados y claves**:
   - **`root.crt`**: Certificado de la autoridad certificadora (CA) que el cliente usa para verificar el servidor.
   - **`postgresql.crt`**: Certificado del cliente.
   - **`postgresql.key`**: Clave privada del cliente.



mkdir ~/.postgresql
cp client.crt client.key root.crt .postgresql/
cd ~/.postgresql	
mv client.crt postgresql.crt
mv client.key postgresql.key
