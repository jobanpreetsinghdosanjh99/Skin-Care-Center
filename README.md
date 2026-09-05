# Skin Care Centre

Clinic management platform with a Flutter client, FastAPI API, and PostgreSQL database.

## Structure

- `mobile_app/` — Flutter client for desktop, web, Android, and iOS
- `backend/` — FastAPI service
- `database/` — PostgreSQL schema

## Initial scope

The first release covers the functionality of the existing clinic system: patients, medicine inventory and stock history, diseases, prescriptions, clinic settings, footer notes, and account access.

## Hosting

Recommended production setup:

- **Backend:** Render web service
- **Database:** Render PostgreSQL
- **Frontend:** any static host for the Flutter web build

If you use the included [render.yaml](./render.yaml), Render will create the API and database together. After deploying:

1. Set `FRONTEND_ORIGIN_REGEX` to your live frontend domain.
2. Point the Flutter web app at the deployed API with `API_BASE_URL`.
3. Run the database schema/migrations against the new PostgreSQL instance.

For Firebase Hosting:

1. Build web with `flutter build web --dart-define=API_BASE_URL=https://skin-care-center.onrender.com`
2. In `mobile_app/`, run `firebase deploy --only hosting`
3. Use [mobile_app/firebase.json](./mobile_app/firebase.json) as the hosting config
