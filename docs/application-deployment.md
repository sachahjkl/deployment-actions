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

Le contrat accepte tout nom d'hôte DNS valide écrit en minuscules.

La plateforme n'impose aucun suffixe de domaine.

Le déploiement refuse un domaine déjà utilisé par une autre route Traefik.

## Publication

Le workflow continu exécute ces opérations :

1. Il vérifie la flake et `application.yaml`.
2. Il construit une image OCI.
3. Il publie l'image dans GHCR.
4. Il produit le SBOM et, sauf avec `build-provenance: false`, la provenance.
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

## Dépôt privé

GitHub produit la provenance de build d'un dépôt privé uniquement avec GitHub Enterprise Cloud.

Pour un autre dépôt privé, passez `build-provenance: false` aux deux workflows partagés.

Le workflow continu ne publie alors pas la provenance.

La promotion ne vérifie alors pas la provenance.

La signature Cosign et l'attestation SBOM restent actives.

Cosign enregistre la signature dans le journal public Rekor.

Ce journal expose le nom du dépôt privé et le condensat de l'image.

Le workflow appelant accorde ces permissions au workflow continu :

- `attestations: write` ;
- `contents: read` ;
- `id-token: write` ;
- `packages: write`.

GitHub refuse l'appel si une permission demandée par le workflow partagé manque.

Exemple pour `petitpecule/service` :

```yaml
jobs:
  ci:
    permissions:
      attestations: write
      contents: read
      id-token: write
      packages: write
    uses: sachahjkl/deployment-actions/.github/workflows/application-ci.yml@v6.1.0
    with:
      deployment-environment: production
      build-provenance: false
      tailscale-oauth-client-id: IDENTIFIANT_DU_CLIENT_TAILSCALE_PETITPECULE
```

## Autre propriétaire GitHub

Un identifiant Tailscale de confiance accepte un seul motif de sujet GitHub.

Un dépôt d'un autre propriétaire GitHub demande un identifiant Tailscale distinct.

Passez cet identifiant avec `tailscale-oauth-client-id` aux deux workflows partagés.

Sans cette entrée, les workflows utilisent l'identifiant de `sachahjkl`.

Le propriétaire doit aussi figurer dans
`services.nomadPlatform.githubActions.owners` de `nixconfig`.

## Création d'une application

Utilisez une version sémantique immuable :

```bash
nix run github:sachahjkl/deployment-actions/v6.0.4#applicationCreate -- \
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
`services.nomadPlatform.namespaces` sur le cluster cible.

Cette liste configure la découverte Traefik.

Elle configure une politique Nomad distincte par environnement.

La règle OIDC associe chaque environnement GitHub à la politique Nomad correspondante.
