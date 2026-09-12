# deployment-actions

Ce dépôt fournit les workflows GitHub réutilisables et la commande de création des applications.

Les applications appellent les workflows depuis des fichiers courts épinglés sur une version immuable.

Créez une application avec cette commande :

```bash
nix run github:sachahjkl/deployment-actions#applicationCreate -- \
  --repository example \
  --application example \
  --environment staging=staging.example.sacha.house \
  --environment production=example.sacha.house \
  --deployment-environment staging \
  --no-index-environment staging \
  --approval-environment production
```
