# Imágenes del Carrusel

## Dimensiones Recomendadas

Para el carrusel del dashboard, las imágenes deben tener:

- **Ancho**: 1200px (mínimo)
- **Alto**: 600-800px (recomendado)
- **Aspecto**: 16:9 o 3:2 funciona mejor
- **Formato**: JPG o PNG
- **Peso**: Máximo 500KB por imagen (para carga rápida)

## Cómo Agregar Imágenes

1. Coloca tus imágenes aquí con nombres descriptivos:
   - `promo_1.jpg`
   - `promo_2.jpg`
   - `promo_3.jpg`
   - etc.

2. La aplicación recorta y adapta automáticamente usando `BoxFit.cover`
   - Esto significa que la imagen se ajustará al espacio disponible
   - Se recortará si es necesario para mantener las proporciones

## Imágenes de Ejemplo (temporales)

Por ahora usa estas URLs de placeholder mientras agregas tus propias imágenes:
- Peluquería moderna
- Estilistas trabajando
- Productos de cabello
- Promociones especiales

## Nota
Una vez que agregues tus imágenes, actualiza el array `carouselImages` en 
`client_dashboard_page.dart` para usar las rutas locales:

```dart
List<String> carouselImages = [
  'assets/images/carousel/promo_1.jpg',
  'assets/images/carousel/promo_2.jpg',
  'assets/images/carousel/promo_3.jpg',
];
```
