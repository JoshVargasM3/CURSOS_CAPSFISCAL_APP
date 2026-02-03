# CAPFISCAL App (Flutter + Firebase + Cloud Functions + Stripe)

Repositorio listo para ejecutar en local una primera versión usable de la app de CAPFISCAL con pagos, QR por curso y check-in en tiempo real.

## Requisitos previos

- Flutter SDK 3.2+
- Node.js 18+
- Firebase CLI (`npm i -g firebase-tools`)
- Cuenta de Firebase (proyecto creado)
- Stripe account (test mode)
- Emuladores Android/iOS o dispositivo físico

## Estructura

```
/ (repo)
  /flutter_app
  /functions
  firebase.json
  firestore.rules
  firestore.indexes.json
  storage.rules
```

## Configuración Firebase

1. Crea un proyecto de Firebase.
2. Habilita **Authentication** → Email/Password.
3. Crea Firestore en modo producción.
4. Crea un bucket de Storage (reglas ya deshabilitan acceso público).

### Flutter (Firebase options)

Opción recomendada: `flutterfire configure`.

```bash
cd flutter_app
flutterfire configure
```

Si prefieres dart-define por JSON (incluido en `flutter_app/dev.json`):

```bash
cd flutter_app
APP_CONFIG=$(cat dev.json)
flutter run --dart-define=APP_CONFIG="$APP_CONFIG"
```

**Nota:** reemplaza los valores `REPLACE_ME` y `pk_test_...` en `dev.json`.

## Configuración Stripe

1. Obtén `STRIPE_SECRET_KEY` y `STRIPE_WEBHOOK_SECRET` desde el dashboard de Stripe.
2. Copia `functions/.env.example` → `functions/.env` y completa los valores.

```bash
cd functions
cp .env.example .env
```

## Deploy de Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

## Reglas e índices

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Ejecutar Flutter

```bash
cd flutter_app
flutter pub get
APP_CONFIG=$(cat dev.json)
flutter run --dart-define=APP_CONFIG="$APP_CONFIG"
```

## Flujo de prueba completo

1. **Admin**: registra un usuario y asigna rol `admin` manualmente desde Firebase Console (Custom Claims) la primera vez.
2. Inicia sesión como admin y crea cursos + sesiones desde la app.
3. Registra un usuario customer.
4. Desde Admin → Roles, asigna rol `checker` o `customer` por email usando la app.
5. Como customer, elige curso y paga (curso completo o sesiones).
6. Stripe webhook actualiza `/payments` y `/enrollments` con estado activo.
7. Como customer, genera el QR del curso.
8. Como checker, selecciona curso + sesión, escanea QR y valida acceso en tiempo real.

## Endpoints Cloud Functions

- `setRole(uid, role)`
- `createPaymentIntentFull(courseId)`
- `createPaymentIntentSessions(courseId, sessionIds)`
- `issueCourseQrToken(courseId)`
- `validateCourseQrToken(token, sessionId)`
- `stripeWebhook`

## Seguridad

- Roles basados en **Custom Claims**.
- El QR contiene solo token firmado (JWT) sin datos personales.
- Descarga de materiales no habilitada (solo metadata). Se deja scaffolding en Firestore.

## Notas de MVP

- La descarga de materiales está deshabilitada; se listan solo metadata.
- Para producción, habilitar validaciones adicionales y UI refinada.
