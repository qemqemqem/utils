# Kubernetes Deployment Commands Usage

## Quick Start

```bash
# Source the script
source ~/Dev/utils/bash/k8s_deploy.sh

# Check what's currently running
whatpods

# Set a service to a specific image tag
setpod edweb andrew_convo_storage
setpod app v4.0.0.0-1234-gabcdef

# Deploy editorweb (auto-detects if clean is needed)
letsed

# Force clean build (slower - use when you suspect issues)
letsed --clean

# Force skip clean (fastest - use when iterating rapidly)
letsed --no-clean

# Deploy copilot
letsco

# Deploy both
letsgo
```

## What's New in letsed v2

### Before (Old letsed)
```bash
# Built image, pushed to ECR
# Tried to delete deployment (often failed)
# Assumed deployment would update (it didn't)
# No verification
# Silent failures
```

### After (New letsed)
```bash
# Builds image, pushes to ECR
# Updates ProphecyCluster resource (source of truth)
# Waits for operator to reconcile
# Verifies pod is running with correct image
# Fails loudly with helpful error messages
```

## Commands Overview

### setpod - Update Service to Specific Tag

Quickly update any service to a specific image tag without rebuilding:

```bash
# Update edweb to a specific tag
setpod edweb andrew_convo_storage

# Update app to a version tag
setpod app v4.0.0.0-1717-ga2b7d8aa98b

# Update with custom namespace
setpod metagraph latest my-namespace
```

**What it does:**
1. Updates the ProphecyCluster resource with the new image
2. Waits for the operator to reconcile
3. Verifies the deployment rolled out successfully
4. Confirms pods are healthy

**Supported services:**
- edweb, copilot, app, metagraph, execution
- sparkedge, lineage, gitserver, metadataui
- artifactory, adminpanel, federator, orchestrator

**Use cases:**
- Roll back to a previous version
- Deploy a branch someone else built
- Quick testing of different versions
- Emergency rollback without rebuilding

---

### whatpods - Check Current Versions

Shows the current versions and status of all running services in your cluster:

```bash
# Check default namespace (prophecy)
whatpods

# Check specific namespace
whatpods my-namespace
```

**Output:**
```
════════════════════════════════════════
📦 Current Service Versions
════════════════════════════════════════

✅ edweb           andrew_convo_storage           Running
✅ app             v4.0.0.0-1717-ga2b7d8aa98b    Running
✅ metagraph       4.2.4.0-SNAPSHOT               Running
⏳ execution       4.2.4.0-SNAPSHOT               Pending
❌ sparkedge       old-tag                        CrashLoopBackOff
```

**Status Icons:**
- ✅ = Running
- ⏳ = Pending
- ❌ = Failed/Unknown

Use this before and after deployments to verify changes!

---

## Understanding the Flow

### Step-by-Step: letsed

1. **Navigate** to ~/prophecy
2. **Smart Clean** - Auto-detects if clean is needed:
   - ✅ Cleans if switching branches
   - ✅ Cleans if `build.sbt` changed
   - ✅ Cleans on first build
   - ⏭️ Skips clean for iterative development
3. **Format** code (`sbt fmt`)
4. **Compile** tests (`sbt editorWeb/Test/compile`)
5. **Authenticate** with AWS ECR
6. **Build & Push** Docker image (tagged with git branch name)
7. **Update** ProphecyCluster resource with new image tag
8. **Verify** deployment rolled out successfully

**Each step must succeed before continuing to the next.**

### Smart Clean Detection

`letsed` automatically determines if a clean build is needed by checking:

1. **Branch changes** - Did you switch branches since last build?
2. **Build config changes** - Did `build.sbt` change (dependencies, versions)?
3. **First build** - Is this the first time running letsed?

**The script tracks state in `~/.letsed_state`** to make smart decisions.

### Manual Control

Sometimes you want to override the auto-detection:

**Force clean (when auto-detect isn't cleaning but you want it):**
```bash
letsed --clean
```

**Force skip clean (when auto-detect wants to clean but you don't):**
```bash
letsed --no-clean
```

**Examples:**
```bash
# Iterating on a bug fix - let it auto-decide
letsed

# Weird compilation errors - force clean
letsed --clean

# Rapid iteration, trust incremental - force skip
letsed --no-clean
```

💡 **Tip:** Just run `letsed` and let it decide! It will clean when needed and skip when safe.

### The ProphecyCluster Pattern

```
Git Branch: andrew_feature_x
    ↓
Docker Image: editorweb:andrew_feature_x
    ↓
ProphecyCluster CR: spec.edweb.image = editorweb:andrew_feature_x
    ↓
Operator reconciles
    ↓
Deployment updated with new image
    ↓
Kubernetes rolling update
    ↓
New pod running with your code
```

## Output Guide

### Success Looks Like

```
════════════════════════════════════════
🚀 Starting edweb deployment
════════════════════════════════════════

📁 Step 1/7: Navigating to project directory
✅ Current directory: /Users/andrew/prophecy
🏷️  Image tag will be: andrew_feature_x

🧹 Step 2/7: Cleaning build artifacts
✅ Clean complete

✨ Step 3/7: Formatting code
✅ Code formatted

🧪 Step 4/7: Compiling tests
✅ Tests compiled

🔐 Step 5/7: Authenticating with ECR
✅ ECR authentication successful

🐳 Step 6/7: Building and pushing Docker image
✅ Image pushed: 133450206866.dkr.ecr.us-west-1.amazonaws.com/editorweb:andrew_feature_x

☸️  Step 7/7: Updating Kubernetes deployment
🔄 Updating ProphecyCluster 'cp' to use image: ...
✅ ProphecyCluster updated successfully

⏳ Waiting for deployment to roll out...
✅ Deployment rollout complete
🔍 Verifying image tag...
✅ Image tag verified
🔍 Checking pod health...
✅ Pod is ready and healthy

════════════════════════════════════════
✅ Deployment successful!
════════════════════════════════════════
📦 Image:    133450206866.dkr.ecr.us-west-1.amazonaws.com/editorweb:andrew_feature_x
⏱️  Duration: 180 seconds
🕐 Completed: Mon Nov 25 14:52:30 EST 2025
```

### Failure Looks Like

```
🧪 Step 4/7: Compiling tests
[error] /Users/andrew/prophecy/modules/editor/eweb/app/controllers/MyController.scala:42:15: not found: value badVariable
❌ Test compilation failed
```

**Command stops immediately. No image is built or deployed.**

## Troubleshooting

### Issue: ECR Authentication Failed

**Error:**
```
❌ ECR authentication failed
```

**Solutions:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Refresh credentials (if using SSO)
aws sso login

# Check region
aws configure get region  # Should be us-west-1
```

---

### Issue: ProphecyCluster Update Failed

**Error:**
```
❌ Failed to update ProphecyCluster
```

**Solutions:**
```bash
# Check if ProphecyCluster exists
kubectl get ProphecyCluster -n prophecy

# Check permissions
kubectl auth can-i patch ProphecyCluster -n prophecy

# Check cluster connectivity
kubectl cluster-info
```

---

### Issue: Deployment Verification Failed

**Error:**
```
❌ Deployment verification failed
🔍 Debugging commands:
   kubectl get pods -n prophecy | grep edweb
   kubectl logs -n prophecy -l app=edweb -c edweb --tail=50
```

**What to do:**
1. Run the suggested debugging commands
2. Check pod logs for errors
3. Check if dependencies (metagraph) are healthy
4. Verify ProphecyCluster operator is running

```bash
# Check operator
kubectl get pods -n prophecy | grep operator

# Check dependencies
kubectl get pods -n prophecy | grep -E "(metagraph|artifactory|sparkedge)"
```

---

### Issue: Wrong Image Tag

**Problem:** You pushed `andrew_feature_x` but want `andrew_feature_y`

**Solution:** Just run `letsed` again after switching branches
```bash
git checkout feature_y
letsed
```

Or manually update:
```bash
update_prophecy_image "prophecy" "edweb" \
  "133450206866.dkr.ecr.us-west-1.amazonaws.com/editorweb:andrew_feature_y"
```

---

## Advanced Usage

### Manual ProphecyCluster Update

```bash
# Update image directly
update_prophecy_image "prophecy" "edweb" \
  "133450206866.dkr.ecr.us-west-1.amazonaws.com/editorweb:my_tag" \
  "cp"
```

### Manual Verification

```bash
# Verify deployment after manual changes
verify_deployment "prophecy" "edweb" \
  "133450206866.dkr.ecr.us-west-1.amazonaws.com/editorweb:my_tag" \
  300  # timeout in seconds
```

### Check Current State

```bash
# What image is ProphecyCluster configured for?
kubectl get ProphecyCluster cp -n prophecy \
  -o jsonpath='{.spec.edweb.image}'

# What image is actually running?
kubectl get deployment edweb-prophecy -n prophecy \
  -o jsonpath='{.spec.template.spec.containers[0].image}'

# What's the pod status?
kubectl get pods -n prophecy | grep edweb
```

---

## Comparison with Old pkdel Approach

### Old Way (Fragile)
```bash
# 1. Build and push image
sbt editorWeb/docker:publish

# 2. Delete deployment
pkdel prophecy edweb  # Often fails silently

# 3. Hope operator recreates with new image
# (It doesn't - uses old tag from ProphecyCluster)
```

### New Way (Robust)
```bash
# 1. Build and push image
sbt editorWeb/docker:publish

# 2. Update ProphecyCluster (source of truth)
update_prophecy_image "prophecy" "edweb" "new_image"

# 3. Operator detects change and reconciles
# (Guaranteed to use new image)

# 4. Verify it worked
verify_deployment "prophecy" "edweb" "new_image"
```

---

## Integration with Shell

### Add to ~/.zshrc or ~/.bashrc

```bash
# Kubernetes deployment commands
if [ -f ~/Dev/utils/bash/k8s_deploy.sh ]; then
  source ~/Dev/utils/bash/k8s_deploy.sh
fi
```

### Verify Loaded

```bash
# After sourcing, you should see:
✅ Kubernetes deployment commands loaded
   Commands available: letsed, letsco, letsgo
   Helper functions: pkdel, update_prophecy_image, verify_deployment

# Test it
type letsed
# Output: letsed is a function
```

---

## Best Practices

### 1. Use Descriptive Branch Names
Your git branch becomes the image tag:
- `feature/new-ui` → `editorweb:feature-new-ui`
- `andrew_debug` → `editorweb:andrew_debug`
- `bugfix-123` → `editorweb:bugfix-123`

### 2. Test Locally First
Before deploying:
```bash
sbt editorWeb/Test/test  # Run full test suite
```

### 3. Watch the Logs
After deployment:
```bash
kubectl logs -n prophecy -l app=edweb -c edweb -f
```

### 4. Check Dependencies
Before deploying edweb:
```bash
kubectl get pods -n prophecy | grep metagraph
# Should show Running
```

### 5. Keep Images Clean
Periodically clean up old images from ECR:
```bash
# List images
aws ecr describe-images --repository-name editorweb --region us-west-1

# Delete old images (be careful!)
# aws ecr batch-delete-image --repository-name editorweb --region us-west-1 --image-ids imageTag=old_tag
```

---

## FAQ

**Q: How long does letsed take?**
A: Typically 3-5 minutes total (2-3 min for build, 1-2 min for deployment)

**Q: Can I deploy to a different namespace?**
A: Yes, but you'll need to modify the script. The namespace is hardcoded to `prophecy`.

**Q: What if I need to rollback?**
A: 
```bash
kubectl rollout undo deployment/edweb-prophecy -n prophecy
```

**Q: Can I run letsed in parallel with someone else?**
A: Yes! As long as you use different branch names, your images won't conflict.

**Q: Does letsed work with multiple clusters?**
A: It uses whatever cluster your kubectl is configured for. Check with `kubectl config current-context`

**Q: What happened to the old letsed?**
A: This is the new version. The old one had issues with silent failures. If you need the old behavior, you can find it in your shell history.

---

## Emergency Recovery

### If deployment is broken and letsed won't fix it:

```bash
# 1. Check what's actually running
kubectl get pods -n prophecy | grep edweb
kubectl describe pod <pod-name> -n prophecy

# 2. Force delete the pod (deployment will recreate)
kubectl delete pod <pod-name> -n prophecy

# 3. Rollback to previous version
kubectl rollout undo deployment/edweb-prophecy -n prophecy

# 4. Nuclear option - delete and let operator rebuild
kubectl delete deployment edweb-prophecy -n prophecy
```

---

## Support

For issues or questions:
1. Check the logs: `kubectl logs -n prophecy -l app=edweb -c edweb --tail=100`
2. Check pod events: `kubectl get events -n prophecy --sort-by='.lastTimestamp' | grep edweb`
3. Refer to ~/Dev/eng/kubernetes/letsed.md for detailed troubleshooting

**Stay the course with robust deployments!** 🎯

