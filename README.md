# utils
Various utils and configs.

## Kubernetes Deployment Commands

The `bash/k8s_deploy.sh` script provides robust deployment commands for the Prophecy Kubernetes cluster.

### Setup

Source the script in your shell configuration:

```bash
# Add to ~/.zshrc or ~/.bashrc
source ~/Dev/utils/bash/k8s_deploy.sh
```

Or run it directly:

```bash
source ~/Dev/utils/bash/k8s_deploy.sh
```

### Commands

**`setpod`** - Update any service to a specific image tag
- Quick deployment without rebuilding
- Perfect for rollbacks or testing versions
- Example: `setpod edweb andrew_convo_storage`
- Supports all major services (edweb, app, metagraph, etc.)

**`whatpods`** - Show current versions of all running services
- Quick status check for all deployments
- Shows image tags and pod health
- Use before/after deployments to verify changes

**`letsed`** - Deploy editorweb with smart clean detection
- Auto-detects when clean is needed (branch/config changes)
- Formats and compiles tests
- Builds and pushes Docker image to ECR
- Updates ProphecyCluster with new image
- Verifies deployment succeeded
- Includes fail-fast error handling
- Override with `letsed --clean` or `letsed --no-clean`

**`letsco`** - Deploy copilot
- Authenticates with ECR
- Builds and pushes copilot image
- Deploys to Kubernetes

**`letsgo`** - Deploy both copilot and edweb
- Runs `letsco` then `letsed`
- Stops if either fails

### Features

- ✅ **Operator-aware** - Updates ProphecyCluster resource (source of truth)
- ✅ **Verification** - Confirms pods are running with correct image
- ✅ **Fail-fast** - Stops immediately on errors
- ✅ **Clear output** - Color-coded status messages
- ✅ **Debugging help** - Provides commands when failures occur

### Helper Functions

- `update_prophecy_image <namespace> <component> <image> [cluster]` - Update ProphecyCluster image
- `verify_deployment <namespace> <component> <image> [timeout]` - Verify deployment health
- `pkdel <namespace> <prefix>` - Delete deployments (improved version)

---

## Including in Pycharm
If you are using mypyutils in PyCharm, you can clone this repo into a sibling directory and do this:
1. Open settings, go to "Project Structure"
2. Add Content Root, select utils
3. Great you can now import mypyutils
