# Déploiement des applications

Ce dépôt contient la politique de déploiement et les outils partagés des applications.

`nixconfig` contient uniquement l'infrastructure du cluster et ses autorisations.

## Dépôt d'application

Chaque dépôt contient uniquement les éléments propres à l'application :

- le code source et les tests ;
- la définition de l'image OCI ;
- `application.yaml` ;
- les petits modules Nomad placés dans `deploy/` ;
- les deux workflows GitHub appelants.

Ne copiez pas les outils partagés dans un dépôt d'application.

Ne copiez pas le modèle Nomad complet dans un dépôt d'application.

Les deux workflows locaux définissent les événements GitHub et les permissions.

Ils définissent aussi la version immuable des workflows partagés.

Un workflow réutilisable ne reçoit pas directement les événements d'un autre dépôt.

## Environnements

`application.yaml` accepte tout nom d'environnement conforme à une étiquette DNS.

Le nom utilise des minuscules.

Chaque environnement déclare son domaine exact.

La commande de création distingue trois listes :

- l'environnement déployé après chaque publication ;
- les environnements qui demandent une approbation ;
- les environnements qui interdisent l'indexation.

La plateforme ne valide pas et ne limite pas les domaines.

## Publication

Le workflow continu exécute ces opérations :

1. Il vérifie la flake et `application.yaml`.
2. Il construit une image OCI.
3. Il publie l'image dans GHCR.
4. Il produit le SBOM et la provenance.
5. Il signe le condensat avec Cosign et GitHub OIDC.
6. Il déploie le condensat dans l'environnement continu.
7. Il vérifie le déploiement Nomad et la route HTTP.

Le déploiement utilise toujours une référence `sha256` immuable.

## Promotion

La promotion lit le condensat exécuté dans l'environnement source.

Elle vérifie la signature, le SBOM et la provenance avant le déploiement.

Elle déploie exactement ce condensat dans l'environnement cible.

Configurez une approbation GitHub Environment pour chaque cible concernée.

Ne stockez pas de jeton Nomad permanent dans GitHub.

GitHub Actions échange son identité OIDC contre un jeton Nomad valable 15 minutes.

## Création d'une application

Utilisez une version sémantique immuable :

```bash
nix run github:sachahjkl/deployment-actions/v5.0.2#applicationCreate -- \
  --repository example \
  --application example \
  --environment preview=preview.example.test \
  --environment live=example.test \
  --deployment-environment preview \
  --no-index-environment preview \
  --approval-environment live
```

Ajoutez `--volume-path /data` si l'application utilise un volume persistant.

La commande crée les GitHub Environments et protège la branche par défaut.

Elle utilise `sachahjkl/application-template` avec une version sémantique immuable.

## Infrastructure requise

Déclarez les noms d'environnement dans
`homelab.services.nomad.namespaces` sur le cluster cible.

Cette liste configure la découverte Traefik.

Elle configure une politique Nomad distincte par environnement.

La règle OIDC associe chaque environnement GitHub à la politique Nomad correspondante.
