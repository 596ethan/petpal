# Architecture

## Shape
This repository is a multi-project workspace rather than a single `src` application.

- `Cutepetpost` is the HarmonyOS phone client and drives product priority.
- `petpal-server` owns real backend persistence and API behavior.
- `petpal-admin` exists only to support appointment fulfillment and phone-side status visibility.
- `deploy` provides local infrastructure needed by the backend runtime.

## Direction
The phone MVP should replace mock-backed core flows with real backend persistence in the order defined by `docs/phone-mvp.md`.

Backend and admin work should be introduced only when it directly supports a phone client use case.
