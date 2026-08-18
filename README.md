# Pendientes Luijo

Tablero Kanban simple para llevar los pendientes de tu equipo (Luis Jose Alvarez,
Soul Tovar, Laura Zamora, Hector Moreira, Alejandro Martinez, Vania Freyre).
Es un único archivo HTML (sin build, sin frameworks) que guarda todo en Supabase,
así que puedes vivir tanto en GitHub Pages como en cualquier otro hosting estático.

## Qué incluye

- `index.html` — la app completa (HTML + CSS + JS en un solo archivo).
- `schema.sql` — script para crear las tablas en Supabase y precargar tu equipo.
- Tablero con 3 columnas (Por hacer / En progreso / Hecho), arrastrar y soltar.
- Prioridad, proyecto/etiqueta, fecha límite (con aviso de vencido/próximo) y
  comentarios/historial por pendiente.
- Filtro por persona y por proyecto, buscador.
- Acceso compartido con un código simple (no es autenticación real, ver
  sección "Sobre la seguridad" abajo).
- Actualización en vivo: si dos personas tienen la página abierta, los cambios
  de una se reflejan en la otra sin recargar.

## 1. Crear el proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com), crea una cuenta si no tienes, y
   crea un **New project** (elige la región más cercana, ej. `us-east-1`).
2. Cuando el proyecto esté listo, ve a **SQL Editor** → **New query**.
3. Copia y pega todo el contenido de `schema.sql` y dale **Run**. Esto crea
   las tablas `team_members`, `pendientes`, `comentarios`, activa las
   políticas de acceso y precarga a tu equipo.
4. Ve a **Project Settings → API**. Copia:
   - **Project URL** (algo como `https://xxxxx.supabase.co`)
   - **anon public key** (una clave larga que empieza distinto a la `service_role`,
     **nunca uses la `service_role` en este archivo**, esa es secreta).

## 2. Configurar index.html

Abre `index.html` y busca la sección `CONFIG` cerca del final del archivo:

```js
const CONFIG = {
  SUPABASE_URL: 'YOUR_SUPABASE_URL',
  SUPABASE_ANON_KEY: 'YOUR_SUPABASE_ANON_KEY',
  ACCESS_CODE: 'cambia-este-codigo',
};
```

Reemplaza los tres valores:
- `SUPABASE_URL` y `SUPABASE_ANON_KEY` con lo que copiaste en el paso anterior.
- `ACCESS_CODE` con la clave que quieras compartir con tu equipo para entrar
  a la app (ej. `luijo2026`).

Guarda el archivo.

## 3. Subir a GitHub

```bash
git init
git add index.html schema.sql README.md
git commit -m "Pendientes Luijo: tablero inicial"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/pendientes-luijo.git
git push -u origin main
```

## 4. Activar GitHub Pages

1. En tu repositorio de GitHub, ve a **Settings → Pages**.
2. En **Source**, elige la rama `main` y la carpeta `/ (root)`.
3. Guarda. En un par de minutos tu tablero estará disponible en algo como:
   `https://TU-USUARIO.github.io/pendientes-luijo/`
4. Comparte esa liga y el código de acceso con tu equipo.

## Cómo se usa

1. Cada persona entra con la liga y escribe el código de acceso compartido.
2. La primera vez, elige su nombre de una lista (así se identifican sus
   comentarios). Esto se guarda en su navegador, no hace falta repetirlo.
3. Arrastra tarjetas entre columnas para cambiar el estado, o haz clic en una
   tarjeta para editar detalles, cambiar responsable, prioridad, fecha límite
   o agregar un comentario.
4. "+ Nuevo pendiente" crea uno nuevo.

## Agregar o quitar personas del equipo más adelante

Ve al **SQL Editor** de Supabase y corre, por ejemplo:

```sql
-- Agregar a alguien nuevo
insert into team_members (name) values ('Nombre Apellido');

-- Dar de baja a alguien (no se borra su historial, solo deja de aparecer)
update team_members set active = false where name = 'Nombre Apellido';
```

## Sobre la seguridad (léelo)

Elegiste el modelo de **acceso compartido simple**: no hay cuentas
individuales, todo el equipo usa la misma `anon key` de Supabase y el mismo
código de acceso. Esto es rápido de montar y suficiente para un equipo de
confianza, pero ten en cuenta:

- El código de acceso es solo una barrera de entrada dentro de la app; no
  encripta ni oculta los datos. Cualquiera que inspeccione el código fuente
  de la página podría ver la `anon key` y el código.
- Las políticas de la base de datos (RLS) están abiertas para el rol `anon`:
  cualquiera con la `anon key` puede leer y escribir en las tablas. Es lo
  esperado para este modelo, ya que la `anon key` viaja dentro del HTML.
- No compartas la liga fuera de tu equipo, y no subas el repositorio como
  público si prefieres que el código/`anon key` no sean visibles para
  cualquiera (puedes usar un repo privado de GitHub y Pages sigue
  funcionando en planes de pago; en repos públicos gratuitos, Pages también
  es pública).
- Si más adelante quieres seguridad real (que cada quien solo pueda editar
  o ver ciertos pendientes), el siguiente paso natural es migrar a
  **Supabase Auth** con login individual y políticas RLS por usuario. Si
  llegas a ese punto, dímelo y te ayudo a hacer el cambio.

## Personalizar

Todo el diseño (colores, columnas, textos) está en `index.html`, en las
etiquetas `<style>` y `<script>`. Es un solo archivo, así que puedes editarlo
directamente sin necesidad de instalar nada.
