# CAPFISCAL App (Flutter + Firebase + Cloud Functions + Stripe)

Repositorio listo para ejecutar en local una primera versión usable de la app de CAPFISCAL con pagos, QR por curso y check-in en tiempo real.

## Requisitos previos (Windows PowerShell)

```powershell
# Node.js 18+, Flutter 3.2+
# Instalar Firebase CLI
npm i -g firebase-tools

# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli
```

## Configuración Firebase (DEV)

```powershell
firebase login
firebase use capfiscal-app-cursos-dev
```

### FlutterFire (firebase_options.dart)

> En este repo **NO** se hardcodean IDs reales. El archivo `lib/firebase_options.dart` incluido es un stub que falla con un mensaje claro.

```powershell
cd flutter_app
flutterfire configure --project capfiscal-app-cursos-dev --platforms=android,ios --android-package-name com.capfiscal.cursos --ios-bundle-id com.capfiscal.cursos
```

## Variables de entorno (Cloud Functions)

```powershell
cd functions
copy .env.example .env
```

Edita `functions/.env` con:
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `QR_SECRET`

## Deploy de reglas e índices

```powershell
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Deploy de Cloud Functions

```powershell
cd functions
npm install
npm run build
firebase deploy --only functions
```

## Ejecutar Flutter

```powershell
cd flutter_app
flutter pub get
flutter run --dart-define-from-file=dev.json
```

## Ejecutar Admin Web

```powershell
cd admin_web
npm install
npm run dev
```

Configura variables `VITE_FIREBASE_*` en un `.env.local` con los datos del SDK web de tu proyecto.

## Flujo de prueba end-to-end

1. **Admin**: registra un usuario y asigna rol `admin` manualmente en Custom Claims la primera vez.
2. Inicia sesión como admin y crea cursos + sesiones desde la app móvil o Admin Web.
3. Registra un usuario customer.
4. Desde Admin → Asignar roles, asigna `checker` o `customer` por email.
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
- Descarga de materiales deshabilitada (solo metadata).
