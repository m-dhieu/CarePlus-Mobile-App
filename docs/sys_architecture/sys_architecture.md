# Care+ System Architecture

Care+ uses a four-layer architecture to separate the user interface, logic, data access, and storage. This organized setup prevents front-end and backend entanglement while smoothly supporting the application's offline-first approach.

The journey begins at the Presentation Layer, where Flutter screens handle patient features like onboarding, medications, and record sharing, while Firebase Authentication manages secure email sign-ins.

When users interact with these screens, data flows into the State Management Layer. Here, Riverpod handles app logic and refreshes the UI. It was chosen over BLoC because it integrates perfectly with live local database streams.

Bridging the gap to storage, the Repository Layer acts as a middleman, shielding the UI and state managers from direct data-source connections.

...
