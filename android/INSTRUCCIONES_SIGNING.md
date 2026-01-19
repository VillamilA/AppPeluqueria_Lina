# 🔐 CONFIGURACIÓN DE FIRMA DIGITAL (SIGNING) - PRODUCCIÓN

## ⚠️ MUY IMPORTANTE - LEE ESTO ⚠️

Este archivo `key.properties` contiene las credenciales para FIRMAR tu app.
**SI PIERDES ESTE ARCHIVO O LA CONTRASEÑA, NUNCA PODRÁS ACTUALIZAR TU APP EN GOOGLE PLAY**

## 📋 INSTRUCCIONES:

1. **EDITA** el archivo `android/key.properties`
2. **REEMPLAZA** `TU_PASSWORD_AQUI` con la contraseña que usaste al crear el keystore
3. **GUARDA** el archivo

Ejemplo de cómo debe quedar:
```
storePassword=MiPassword123
keyPassword=MiPassword123
keyAlias=lina-peluqueria
storeFile=lina-peluqueria-key.jks
```

## 🔒 SEGURIDAD:

✅ El archivo `key.properties` NO se sube a GitHub (.gitignore)
✅ El archivo `lina-peluqueria-key.jks` NO se sube a GitHub (.gitignore)
⚠️ **GUARDA UNA COPIA DE SEGURIDAD** de ambos archivos en un lugar seguro

## 📦 Archivos importantes:

- `android/lina-peluqueria-key.jks` - Tu keystore (llave digital)
- `android/key.properties` - Configuración de contraseñas
- **Ambos son NECESARIOS para publicar actualizaciones**

## ✅ Para verificar que todo funciona:

```bash
flutter build appbundle --release
```

Si compila sin errores, ¡está listo para producción!
