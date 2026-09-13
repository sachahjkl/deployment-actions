# deployment-actions

Ce dépôt fournit les workflows GitHub réutilisables.

Il fournit aussi la commande de création des applications.

Les applications utilisent des fichiers courts.

Chaque fichier épingle le workflow partagé sur une version immuable.

Consultez
[`docs/application-deployment.md`](docs/application-deployment.md)
pour la politique et l'intégration d'une application.

Créez une application avec cette commande :

```bash
nix run github:sachahjkl/deployment-actions/v6.0.3#applicationCreate -- \
  --repository example \
  --application example \
  --environment staging=staging.example.sacha.house \
  --environment production=example.sacha.house \
  --deployment-environment staging \
  --no-index-environment staging \
  --approval-environment production
```
