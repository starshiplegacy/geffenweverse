# GeffenWeverse

GeffenWeverse is a community and fan-platform project within the Starship Legacy ecosystem.

## Repository

This repository is the central source-control location for the GeffenWeverse web application and its supporting backend assets.

## Project structure

```
.
├── geffenweverse-web.html  # frontend file to be added
├── README.md
├── .gitignore
└── supabase/
    └── migrations/
```

The migration directory contains the database changes in chronological order. Apply migrations only to the intended Supabase project and review each SQL file before running it.

## Development

The planned web frontend is a standalone HTML application. Once `geffenweverse-web.html` is added, it can be opened in a modern browser for a local visual review.

Backend services and environment-specific settings must be configured separately. Do not commit API secrets, service-role keys, database passwords, access tokens, or private credentials.

## Database migrations

Supabase migration files are stored in `supabase/migrations/` and use timestamp-prefixed filenames. Apply them in ascending filename order using the Supabase CLI or the project's approved migration workflow.

## Security

- Keep Row Level Security enabled on tables containing user or application data.
- Use only publishable client keys in browser code.
- Keep privileged keys and server-side credentials outside the repository.
- Review schema and policy changes before applying them to production.

## Status

This repository is being prepared as the shared source of truth for GeffenWeverse. Deployment configuration and environment-specific setup should be documented here when finalized.
