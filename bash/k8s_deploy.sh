#!/bin/bash

# Kubernetes Deployment Commands for Prophecy
# Commands: letsed, letsmeta, letsco, letsgo, whatpods
# Description: Build, push, and deploy services to Kubernetes cluster

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Command: setpod - Update a service to a specific image tag
# Usage: setpod <service> <tag> [namespace]
# Example: setpod edweb andrew_convo_storage
# Example: setpod app v4.0.0.0-1234-gabcdef prophecy
setpod() {
  local service=$1
  local tag=$2
  local namespace="${3:-prophecy}"
  local cluster_name="${4:-cp}"
  
  if [ -z "$service" ] || [ -z "$tag" ]; then
    echo -e "${RED}❌ Usage: setpod <service> <tag> [namespace] [cluster_name]${NC}"
    echo ""
    echo "Examples:"
    echo "  setpod edweb andrew_convo_storage"
    echo "  setpod app v4.0.0.0-1234-gabcdef"
    echo "  setpod metagraph latest prophecy cp"
    return 1
  fi
  
  echo -e "${CYAN}════════════════════════════════════════${NC}"
  echo -e "${CYAN}🔧 Setting ${service} image${NC}"
  echo -e "${CYAN}════════════════════════════════════════${NC}"
  echo ""
  
  # Map service names to image repos and container names
  local image_repo=""
  case "$service" in
    edweb)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/editorweb"
      ;;
    copilot)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/copilot"
      ;;
    app)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/app"
      ;;
    metagraph)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/metagraph"
      ;;
    execution)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/execution"
      ;;
    sparkedge)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/sparkedge"
      ;;
    lineage)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/lineage"
      ;;
    gitserver)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/gitserver"
      ;;
    metadataui)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/metadataui"
      ;;
    artifactory)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/artifactory"
      ;;
    adminpanel)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/adminpanel"
      ;;
    federator)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/federator"
      ;;
    orchestrator)
      image_repo="133450206866.dkr.ecr.us-west-1.amazonaws.com/orchestrator"
      ;;
    *)
      echo -e "${RED}❌ Unknown service: ${service}${NC}"
      echo ""
      echo "Known services: edweb, copilot, app, metagraph, execution, sparkedge,"
      echo "                lineage, gitserver, metadataui, artifactory, adminpanel,"
      echo "                federator, orchestrator"
      return 1
      ;;
  esac
  
  local full_image="${image_repo}:${tag}"
  
  echo -e "${BLUE}📦 Service:   ${service}${NC}"
  echo -e "${BLUE}🏷️  New tag:   ${tag}${NC}"
  echo -e "${BLUE}🖼️  Full image: ${full_image}${NC}"
  echo ""
  
  # Update ProphecyCluster
  echo -e "${BLUE}🔄 Updating ProphecyCluster '${cluster_name}'...${NC}"
  update_prophecy_image "${namespace}" "${service}" "${full_image}" "${cluster_name}" || {
    echo -e "${RED}❌ Failed to update ProphecyCluster${NC}"
    return 1
  }
  
  echo ""
  echo -e "${BLUE}⏳ Waiting for deployment to roll out...${NC}"
  sleep 5  # Give operator a moment to reconcile
  
  # Verify deployment (with 5 minute timeout)
  verify_deployment "${namespace}" "${service}" "${full_image}" 300 || {
    echo -e "${YELLOW}⚠️  Deployment verification had issues${NC}"
    echo -e "${YELLOW}   Check with: kubectl get pods -n ${namespace} | grep ${service}${NC}"
    return 1
  }
  
  echo ""
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}✅ ${service} updated successfully!${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo ""
  
  return 0
}

# Command: whatpods - Show current versions of running services
whatpods() {
  local namespace="${1:-prophecy}"
  
  echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}📦 Current Service Versions${NC}"
  echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
  echo ""
  
  # Header
  printf "   %-22s %-28s %-20s %s\n" "SERVICE" "TAG" "STATUS" "AGE"
  printf "   %-22s %-28s %-20s %s\n" "-------" "---" "------" "---"
  
  # List of key services to check
  local services=(
    "edweb:edweb-prophecy"
    "app:app-prophecy"
    "metagraph:metagraph-prophecy"
    "execution:execution-prophecy"
    "sparkedge:sparkedge-prophecy"
    "copilot:copilot-prophecy"
    "lineage:lineage-prophecy"
    "gitserver:gitserver-prophecy"
    "metadataui (frontend):metadataui-prophecy"
    "artifactory:artifactory-prophecy"
    "orchestrator:orchestrator-prophecy"
  )
  
  for service_def in "${services[@]}"; do
    IFS=':' read -r service_name deployment_name <<< "$service_def"
    
    # Extract component name for label queries (strip any parenthetical like "(frontend)")
    local component_name=$(echo "$service_name" | awk '{print $1}')
    
    # Get the image from the deployment
    local image=$(kubectl get deployment "${deployment_name}" -n "${namespace}" \
      -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
    
    if [ -n "$image" ]; then
      # Extract just the tag from the full image
      local tag=$(echo "$image" | awk -F: '{print $NF}')
      
      # Get pod info in one call for efficiency
      local pod_info=$(kubectl get pods -n "${namespace}" -l "prophecy.io/component=${component_name}" \
        -o jsonpath='{.items[0].metadata.name}|{.items[0].status.phase}|{.items[0].status.containerStatuses[*].ready}|{.items[0].status.containerStatuses[*].state.waiting.reason}' 2>/dev/null)
      
      local pod_name=$(echo "$pod_info" | cut -d'|' -f1)
      local pod_phase=$(echo "$pod_info" | cut -d'|' -f2)
      local ready_status=$(echo "$pod_info" | cut -d'|' -f3)
      local waiting_reason=$(echo "$pod_info" | cut -d'|' -f4)
      
      # Get pod age
      local pod_age=""
      if [ -n "$pod_name" ]; then
        pod_age=$(kubectl get pod "$pod_name" -n "${namespace}" \
          -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null)
        if [ -n "$pod_age" ]; then
          # Convert to human-readable age (timestamps are UTC)
          local now=$(date +%s)
          local created=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$pod_age" +%s 2>/dev/null || date -u -d "$pod_age" +%s 2>/dev/null)
          if [ -n "$created" ]; then
            local age_secs=$((now - created))
            if [ $age_secs -lt 60 ]; then
              pod_age="${age_secs}s"
            elif [ $age_secs -lt 3600 ]; then
              pod_age="$((age_secs / 60))m"
            elif [ $age_secs -lt 86400 ]; then
              pod_age="$((age_secs / 3600))h"
            else
              pod_age="$((age_secs / 86400))d"
            fi
          fi
        fi
      fi
      
      # Determine display status (show waiting reason if present)
      local display_status="$pod_phase"
      if [ -n "$waiting_reason" ]; then
        display_status="$waiting_reason"
      elif [ "$pod_phase" = "Running" ] && [[ "$ready_status" =~ false ]]; then
        display_status="NotReady"
      fi
      
      # Color code based on status
      local status_color=""
      local status_icon=""
      if [ "$pod_phase" = "Running" ] && [[ ! "$ready_status" =~ false ]] && [ -z "$waiting_reason" ]; then
        # Running and all containers ready
        status_color="${GREEN}"
        status_icon="✅"
      elif [ "$pod_phase" = "Running" ] && [[ "$ready_status" =~ false ]]; then
        # Running but not all containers ready
        status_color="${YELLOW}"
        status_icon="⚠️"
      elif [ "$pod_phase" = "Pending" ]; then
        status_color="${YELLOW}"
        status_icon="⏳"
      elif [ "$waiting_reason" = "ImagePullBackOff" ] || [ "$waiting_reason" = "ErrImagePull" ]; then
        status_color="${RED}"
        status_icon="🖼️"
      elif [ "$waiting_reason" = "CrashLoopBackOff" ]; then
        status_color="${RED}"
        status_icon="💥"
      else
        status_color="${RED}"
        status_icon="❌"
      fi
      
      printf "${status_color}${status_icon}${NC} %-22s ${BLUE}%-28s${NC} ${status_color}%-20s${NC} %s\n" \
        "$service_name" "$tag" "$display_status" "$pod_age"
    else
      printf "${YELLOW}⚠️${NC}  %-22s ${YELLOW}%-28s${NC} ${YELLOW}%-20s${NC} %s\n" \
        "$service_name" "(no deployment)" "N/A" "-"
    fi
  done
  
  echo ""
  echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "Legend: ✅ Running  ⚠️ NotReady  ⏳ Pending  🖼️ ImagePull  💥 CrashLoop  ❌ Failed"
  echo ""
  
  return 0
}

# Helper function: Update ProphecyCluster image
update_prophecy_image() {
  local namespace=$1
  local component=$2
  local new_image=$3
  local cluster_name=${4:-cp}  # Default to 'cp'
  
  echo -e "${BLUE}🔄 Updating ProphecyCluster '${cluster_name}' to use image: ${new_image}${NC}"
  
  # Check if the component has an image field
  local current_image=$(kubectl get ProphecyCluster "${cluster_name}" -n "${namespace}" \
    -o jsonpath="{.spec.${component}.image}" 2>/dev/null)
  
  local same_tag=false
  if [ -z "$current_image" ]; then
    echo -e "${YELLOW}⚠️  No image field found for ${component} in ProphecyCluster${NC}"
    echo "   The operator may be using default image tags"
    echo "   Adding image field to ProphecyCluster spec..."
  else
    echo "   Current image: ${current_image}"
    if [ "${current_image}" = "${new_image}" ]; then
      same_tag=true
      echo -e "${YELLOW}   ⚠️  Same image tag - will force pod restart${NC}"
    fi
  fi
  
  # Update the image (try replace first, then add if that fails)
  kubectl patch ProphecyCluster "${cluster_name}" -n "${namespace}" \
    --type='json' \
    -p="[{\"op\": \"replace\", \"path\": \"/spec/${component}/image\", \"value\": \"${new_image}\"}]" 2>/dev/null
  
  if [ $? -ne 0 ]; then
    # If replace fails, try add (field might not exist)
    kubectl patch ProphecyCluster "${cluster_name}" -n "${namespace}" \
      --type='json' \
      -p="[{\"op\": \"add\", \"path\": \"/spec/${component}/image\", \"value\": \"${new_image}\"}]"
  fi
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ ProphecyCluster updated successfully${NC}"
    
    # If same tag, force a rollout restart to pick up new image
    if [ "$same_tag" = true ]; then
      local deployment_name="${component}-${namespace}"
      echo -e "${BLUE}🔄 Forcing rollout restart for ${deployment_name}...${NC}"
      kubectl rollout restart deployment "${deployment_name}" -n "${namespace}"
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Rollout restart triggered${NC}"
      else
        echo -e "${RED}❌ Failed to trigger rollout restart${NC}"
        return 1
      fi
    fi
    
    return 0
  else
    echo -e "${RED}❌ Failed to update ProphecyCluster${NC}"
    return 1
  fi
}

# Helper function: Verify deployment succeeded
verify_deployment() {
  local namespace=$1
  local component=$2
  local expected_image=$3
  local timeout=${4:-300}  # 5 minutes default
  
  local deployment_name="${component}-${namespace}"
  
  echo -e "${BLUE}⏳ Waiting for deployment rollout: ${deployment_name}${NC}"
  
  # Wait for rollout to complete
  kubectl rollout status deployment/"${deployment_name}" -n "${namespace}" --timeout="${timeout}s"
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Deployment rollout failed or timed out${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✅ Deployment rollout complete${NC}"
  
  # Verify the image tag
  echo -e "${BLUE}🔍 Verifying image tag...${NC}"
  local actual_image=$(kubectl get deployment "${deployment_name}" -n "${namespace}" \
    -o jsonpath='{.spec.template.spec.containers[0].image}')
  
  echo "   Expected: ${expected_image}"
  echo "   Actual:   ${actual_image}"
  
  if [ "${actual_image}" = "${expected_image}" ]; then
    echo -e "${GREEN}✅ Image tag verified${NC}"
  else
    echo -e "${RED}❌ Image tag mismatch!${NC}"
    return 1
  fi
  
  # Check pod status
  echo -e "${BLUE}🔍 Checking pod health...${NC}"
  local pod_name=$(kubectl get pods -n "${namespace}" -l "prophecy.io/component=${component}" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ -z "$pod_name" ]; then
    echo -e "${RED}❌ No pod found for ${component}${NC}"
    return 1
  fi
  
  local ready=$(kubectl get pod "${pod_name}" -n "${namespace}" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
  
  if [ "${ready}" = "True" ]; then
    echo -e "${GREEN}✅ Pod is ready and healthy${NC}"
    echo "   Pod: ${pod_name}"
  else
    echo -e "${YELLOW}⚠️  Pod is not ready yet${NC}"
    echo "   Pod: ${pod_name}"
    echo "   Run: kubectl logs -n ${namespace} ${pod_name} -c ${component}"
    return 1
  fi
  
  return 0
}

# Helper function: Improved pkdel (for backward compatibility, but not used in new letsed)
pkdel() {
  local namespace=$1
  local prefix=$2
  
  echo -e "${BLUE}🔍 Looking for deployments matching: ${prefix}-${namespace} in namespace: ${namespace}${NC}"
  
  local deployments=$(kubectl -n "${namespace}" get deployments -o name 2>/dev/null | grep "deployment.apps/${prefix}-${namespace}")
  
  if [ -z "$deployments" ]; then
    echo -e "${YELLOW}ℹ️  No deployments found matching pattern: ${prefix}-${namespace}${NC}"
    return 0
  fi
  
  echo -e "${BLUE}🗑️  Found deployments to delete:${NC}"
  echo "$deployments" | sed 's|deployment.apps/||'
  
  echo "$deployments" | xargs -L1 kubectl -n "${namespace}" delete
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully deleted deployments${NC}"
    return 0
  else
    echo -e "${RED}❌ Failed to delete some deployments${NC}"
    return 1
  fi
}

# Helper function: Check if clean build is needed
should_clean_build() {
  local state_file=~/.letsed_state
  local current_branch=$(git branch --show-current 2>/dev/null)
  local build_sbt_hash=$(md5 -q build.sbt 2>/dev/null || echo "unknown")
  
  # Always clean if state file doesn't exist
  if [ ! -f "$state_file" ]; then
    echo "first-build"
    return 0
  fi
  
  # Read previous state
  local prev_branch=$(grep "^branch:" "$state_file" | cut -d: -f2)
  local prev_hash=$(grep "^build_sbt:" "$state_file" | cut -d: -f2)
  
  # Check if branch changed
  if [ "$current_branch" != "$prev_branch" ]; then
    echo "branch-change"
    return 0
  fi
  
  # Check if build.sbt changed
  if [ "$build_sbt_hash" != "$prev_hash" ]; then
    echo "build-config-change"
    return 0
  fi
  
  # No clean needed
  echo "skip"
  return 1
}

# Helper function: Save build state
save_build_state() {
  local state_file=~/.letsed_state
  local current_branch=$(git branch --show-current 2>/dev/null)
  local build_sbt_hash=$(md5 -q build.sbt 2>/dev/null || echo "unknown")
  
  cat > "$state_file" <<EOF
branch:$current_branch
build_sbt:$build_sbt_hash
timestamp:$(date +%s)
EOF
}

# Main function: letsed - Deploy editorweb
# Usage: letsed [--clean|--no-clean]
letsed() {
  local start_time=$(date +%s)
  local do_clean=""
  
  # Parse arguments
  if [[ "$1" == "--clean" ]]; then
    do_clean="force"
  elif [[ "$1" == "--no-clean" ]]; then
    do_clean="skip"
  fi
  
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}🚀 Starting edweb deployment${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  
  # Step 1: Navigate and setup
  echo ""
  echo -e "${BLUE}📁 Step 1/7: Navigating to project directory${NC}"
  cd ~/prophecy || {
    echo -e "${RED}❌ Failed to navigate to ~/prophecy${NC}"
    return 1
  }
  echo -e "${GREEN}✅ Current directory: $(pwd)${NC}"
  
  # Get the git branch for image tagging
  local branch=$(git branch --show-current)
  local image_tag=$(echo "$branch" | sed 's/\//-/g')  # Replace slashes
  echo -e "${BLUE}🏷️  Image tag will be: ${image_tag}${NC}"
  
  # Step 2: Clean build (auto-detect or forced)
  echo ""
  if [ "$do_clean" = "force" ]; then
    # Explicitly requested clean
    echo -e "${BLUE}🧹 Step 2/7: Cleaning build artifacts (forced)${NC}"
    sbt clean || {
      echo -e "${RED}❌ sbt clean failed${NC}"
      return 1
    }
    echo -e "${GREEN}✅ Clean complete${NC}"
  elif [ "$do_clean" = "skip" ]; then
    # Explicitly skip clean
    echo -e "${YELLOW}⏭️  Step 2/7: Skipping clean (forced)${NC}"
  else
    # Auto-detect if clean is needed
    local clean_reason=$(should_clean_build)
    if [ $? -eq 0 ]; then
      case "$clean_reason" in
        "first-build")
          echo -e "${BLUE}🧹 Step 2/7: Cleaning build artifacts (first build)${NC}"
          ;;
        "branch-change")
          echo -e "${BLUE}🧹 Step 2/7: Cleaning build artifacts (branch changed)${NC}"
          ;;
        "build-config-change")
          echo -e "${BLUE}🧹 Step 2/7: Cleaning build artifacts (build.sbt changed)${NC}"
          ;;
        *)
          echo -e "${BLUE}🧹 Step 2/7: Cleaning build artifacts${NC}"
          ;;
      esac
      
      sbt clean || {
        echo -e "${RED}❌ sbt clean failed${NC}"
        return 1
      }
      echo -e "${GREEN}✅ Clean complete${NC}"
    else
      echo -e "${YELLOW}⏭️  Step 2/7: Skipping clean (not needed - use '--clean' to force)${NC}"
    fi
  fi
  
  # Step 3: Format code
  echo ""
  echo -e "${BLUE}✨ Step 3/7: Formatting code${NC}"
  sbt fmt || {
    echo -e "${RED}❌ sbt fmt failed${NC}"
    return 1
  }
  echo -e "${GREEN}✅ Code formatted${NC}"
  
  # Step 4: Compile tests
  echo ""
  echo -e "${BLUE}🧪 Step 4/7: Compiling tests${NC}"
  sbt editorWeb/Test/compile || {
    echo -e "${RED}❌ Test compilation failed${NC}"
    return 1
  }
  echo -e "${GREEN}✅ Tests compiled${NC}"
  
  # Step 5: ECR authentication
  echo ""
  echo -e "${BLUE}🔐 Step 5/7: Authenticating with ECR${NC}"
  aws ecr get-login-password --region us-west-1 | \
    docker login --username AWS --password-stdin \
    133450206866.dkr.ecr.us-west-1.amazonaws.com || {
    echo -e "${RED}❌ ECR authentication failed${NC}"
    return 1
  }
  echo -e "${GREEN}✅ ECR authentication successful${NC}"
  
  # Step 6: Build and push image
  echo ""
  echo -e "${BLUE}🐳 Step 6/7: Building and pushing Docker image${NC}"
  
  # Capture SBT output to parse the actual published image name
  local sbt_output=$(mktemp)
  sbt editorWeb/docker:publish 2>&1 | tee "$sbt_output"
  local sbt_exit=${PIPESTATUS[0]}
  
  if [ $sbt_exit -ne 0 ]; then
    rm -f "$sbt_output"
    echo -e "${RED}❌ Docker build/push failed${NC}"
    return 1
  fi
  
  # Parse the actual published image from SBT output
  # SBT outputs: "[info] Published image 133450206866.dkr.ecr.us-west-1.amazonaws.com/editorweb:actual_tag"
  local full_image=$(grep "Published image" "$sbt_output" | tail -1 | awk '{print $NF}')
  rm -f "$sbt_output"
  
  if [ -z "$full_image" ]; then
    echo -e "${RED}❌ Could not parse published image name from SBT output${NC}"
    echo -e "${YELLOW}⚠️  Expected tag was: ${image_tag}${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✅ Image pushed: ${full_image}${NC}"
  
  # Step 7: Update ProphecyCluster and verify
  echo ""
  echo -e "${BLUE}☸️  Step 7/7: Updating Kubernetes deployment${NC}"
  
  update_prophecy_image "prophecy" "edweb" "${full_image}" "cp" || {
    echo -e "${RED}❌ Failed to update ProphecyCluster${NC}"
    return 1
  }
  
  echo ""
  echo -e "${BLUE}⏳ Waiting for deployment to roll out...${NC}"
  sleep 5  # Give operator a moment to reconcile
  
  verify_deployment "prophecy" "edweb" "${full_image}" 300 || {
    echo -e "${RED}❌ Deployment verification failed${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Debugging commands:${NC}"
    echo "   kubectl get pods -n prophecy | grep edweb"
    echo "   kubectl logs -n prophecy -l prophecy.io/component=edweb -c edweb --tail=50"
    echo "   kubectl describe pod -n prophecy -l prophecy.io/component=edweb"
    return 1
  }
  
  # Success! Save build state for future smart clean detection
  save_build_state
  
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  echo ""
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}✅ Deployment successful!${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${BLUE}📦 Image:    ${full_image}${NC}"
  echo -e "${BLUE}⏱️  Duration: ${duration} seconds${NC}"
  echo -e "${BLUE}🕐 Completed: $(date)${NC}"
  echo ""
  
  return 0
}


# Main function: letsmeta - Deploy metagraph
# Usage: letsmeta [--clean|--no-clean]
letsmeta() {
  local start_time=$(date +%s)
  local do_clean=""
  
  # Parse arguments
  if [[ "$1" == "--clean" ]]; then
    do_clean="force"
  elif [[ "$1" == "--no-clean" ]]; then
    do_clean="skip"
  fi
  
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}🚀 Starting metagraph deployment${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  
  # Step 1: Navigate and setup
  echo ""
  echo -e "${BLUE}📁 Step 1/7: Navigating to project directory${NC}"
  cd ~/prophecy || {
    echo -e "${RED}❌ Failed to navigate to ~/prophecy${NC}"
    return 1
  }
  echo -e "${GREEN}✅ Current directory: $(pwd)${NC}"
  
  # Get the git branch for image tagging
  local branch=$(git branch --show-current)
  local image_tag=$(echo "$branch" | sed 's/\//-/g')  # Replace slashes
  echo -e "${BLUE}🏷️  Image tag will be: ${image_tag}${NC}"
  
  # Step 2: Clean build (auto-detect or forced)
  echo ""
  if [ "$do_clean" = "force" ]; then
    # Explicitly requested clean
    echo -e "${BLUE}🧹 Step 2/7: Cleaning build artifacts (forced)${NC}"
    sbt clean || {
      echo -e "${RED}❌ sbt clean failed${NC}"
      return 1
    }
    echo -e "${GREEN}✅ Clean complete${NC}"
  elif [ "$do_clean" = "skip" ]; then
    # Explicitly skip clean
    echo -e "${YELLOW}⏭️  Step 2/7: Skipping clean (forced)${NC}"
  else
    # Auto-detect if clean is needed
    local clean_reason=$(should_clean_build)
    if [ $? -eq 0 ]; then
      case "$clean_reason" in
        "first-build")
          echo -e "${BLUE}🧹 Step 2/7: Cleaning build artifacts (first build)${NC}"
          ;;
        "branch-change")
          echo -e "${BLUE}🧹 Step 2/7: Cleaning build artifacts (branch changed)${NC}"
          ;;
        "build-config-change")
          echo -e "${BLUE}🧹 Step 2/7: Cleaning build artifacts (build.sbt changed)${NC}"
          ;;
        *)
          echo -e "${BLUE}🧹 Step 2/7: Cleaning build artifacts${NC}"
          ;;
      esac
      
      sbt clean || {
        echo -e "${RED}❌ sbt clean failed${NC}"
        return 1
      }
      echo -e "${GREEN}✅ Clean complete${NC}"
    else
      echo -e "${YELLOW}⏭️  Step 2/7: Skipping clean (not needed - use '--clean' to force)${NC}"
    fi
  fi
  
  # Step 3: Format code
  echo ""
  echo -e "${BLUE}✨ Step 3/7: Formatting code${NC}"
  sbt fmt || {
    echo -e "${RED}❌ sbt fmt failed${NC}"
    return 1
  }
  echo -e "${GREEN}✅ Code formatted${NC}"
  
  # Step 4: Compile tests
  echo ""
  echo -e "${BLUE}🧪 Step 4/7: Compiling tests${NC}"
  sbt metadataGraph/Test/compile || {
    echo -e "${RED}❌ Test compilation failed${NC}"
    return 1
  }
  echo -e "${GREEN}✅ Tests compiled${NC}"
  
  # Step 5: ECR authentication
  echo ""
  echo -e "${BLUE}🔐 Step 5/7: Authenticating with ECR${NC}"
  aws ecr get-login-password --region us-west-1 | \
    docker login --username AWS --password-stdin \
    133450206866.dkr.ecr.us-west-1.amazonaws.com || {
    echo -e "${RED}❌ ECR authentication failed${NC}"
    return 1
  }
  echo -e "${GREEN}✅ ECR authentication successful${NC}"
  
  # Step 6: Build and push image
  echo ""
  echo -e "${BLUE}🐳 Step 6/7: Building and pushing Docker image${NC}"
  
  # Capture SBT output to parse the actual published image name
  local sbt_output=$(mktemp)
  sbt metadataGraph/docker:publish 2>&1 | tee "$sbt_output"
  local sbt_exit=${PIPESTATUS[0]}
  
  if [ $sbt_exit -ne 0 ]; then
    rm -f "$sbt_output"
    echo -e "${RED}❌ Docker build/push failed${NC}"
    return 1
  fi
  
  # Parse the actual published image from SBT output
  # SBT outputs: "[info] Published image 133450206866.dkr.ecr.us-west-1.amazonaws.com/metadatagraph:actual_tag"
  local full_image=$(grep "Published image" "$sbt_output" | tail -1 | awk '{print $NF}')
  rm -f "$sbt_output"
  
  if [ -z "$full_image" ]; then
    echo -e "${RED}❌ Could not parse published image name from SBT output${NC}"
    echo -e "${YELLOW}⚠️  Expected tag was: ${image_tag}${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✅ Image pushed: ${full_image}${NC}"
  
  # Step 7: Update ProphecyCluster and verify
  echo ""
  echo -e "${BLUE}☸️  Step 7/7: Updating Kubernetes deployment${NC}"
  
  update_prophecy_image "prophecy" "metagraph" "${full_image}" "cp" || {
    echo -e "${RED}❌ Failed to update ProphecyCluster${NC}"
    return 1
  }
  
  echo ""
  echo -e "${BLUE}⏳ Waiting for deployment to roll out...${NC}"
  sleep 5  # Give operator a moment to reconcile
  
  verify_deployment "prophecy" "metagraph" "${full_image}" 300 || {
    echo -e "${RED}❌ Deployment verification failed${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Debugging commands:${NC}"
    echo "   kubectl get pods -n prophecy | grep metagraph"
    echo "   kubectl logs -n prophecy -l prophecy.io/component=metagraph -c metagraph --tail=50"
    echo "   kubectl describe pod -n prophecy -l prophecy.io/component=metagraph"
    return 1
  }
  
  # Success! Save build state for future smart clean detection
  save_build_state
  
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  echo ""
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}✅ Deployment successful!${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${BLUE}📦 Image:    ${full_image}${NC}"
  echo -e "${BLUE}⏱️  Duration: ${duration} seconds${NC}"
  echo -e "${BLUE}🕐 Completed: $(date)${NC}"
  echo ""
  
  return 0
}

# Function: letsco - Deploy copilot (DEPRECATED)
letsco() {
  echo -e "${YELLOW}════════════════════════════════════════${NC}"
  echo -e "${YELLOW}⚠️  WARNING: letsco is DEPRECATED${NC}"
  echo -e "${YELLOW}════════════════════════════════════════${NC}"
  echo -e "${YELLOW}This command is deprecated and may be removed in a future version.${NC}"
  echo -e "${YELLOW}Please use alternative deployment methods for copilot.${NC}"
  echo ""
  echo -e "${BLUE}Press Enter to continue anyway, or Ctrl+C to cancel...${NC}"
  read
  
  echo ""
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}🚀 Starting copilot deployment${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  
  echo -e "${BLUE}📁 Navigating to copilot directory${NC}"
  cd ~/prophecy/copilot || {
    echo -e "${RED}❌ Failed to navigate to ~/prophecy/copilot${NC}"
    return 1
  }
  
  echo -e "${BLUE}🔐 Authenticating with ECR${NC}"
  aws ecr get-login-password --region us-west-1 | \
    docker login --username AWS --password-stdin \
    133450206866.dkr.ecr.us-west-1.amazonaws.com || {
    echo -e "${RED}❌ ECR authentication failed${NC}"
    return 1
  }
  
  echo -e "${BLUE}🔨 Building application${NC}"
  just build || {
    echo -e "${RED}❌ Build failed${NC}"
    return 1
  }
  
  echo -e "${BLUE}🐳 Pushing Docker image${NC}"
  just docker-push || {
    echo -e "${RED}❌ Docker push failed${NC}"
    return 1
  }
  
  echo -e "${BLUE}☸️  Deploying to Kubernetes${NC}"
  just deploy || {
    echo -e "${RED}❌ Deploy failed${NC}"
    return 1
  }
  
  echo ""
  echo -e "${GREEN}✅ Copilot deployment complete!${NC}"
  echo -e "${BLUE}🕐 Completed: $(date)${NC}"
  echo ""
  
  return 0
}

# Function: letsgo - Deploy both copilot and edweb
letsgo() {
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}🚀 Starting full deployment (copilot + edweb)${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo ""
  
  local start_time=$(date +%s)
  
  # Deploy copilot first
  letsco || {
    echo -e "${RED}❌ Copilot deployment failed, aborting${NC}"
    return 1
  }
  
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Then deploy edweb
  letsed || {
    echo -e "${RED}❌ Edweb deployment failed${NC}"
    return 1
  }
  
  # Success!
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  echo ""
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}🎉 Full deployment successful!${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${BLUE}⏱️  Total Duration: ${duration} seconds${NC}"
  echo -e "${BLUE}🕐 Completed: $(date)${NC}"
  echo ""
  
  return 0
}

# Function: letsagent - Deploy python-sandbox agent to cluster
# Usage: letsagent [--skip-build]
letsagent() {
  local start_time=$(date +%s)
  local skip_build=false
  local namespace="prophecy"
  local deployment_name="ai-agent"
  
  # Parse arguments
  if [[ "$1" == "--skip-build" ]]; then
    skip_build=true
  fi
  
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}🤖 Starting AI Agent deployment${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  
  # Step 1: Navigate to python-sandbox
  echo ""
  echo -e "${BLUE}📁 Step 1/5: Navigating to python-sandbox${NC}"
  cd ~/prophecy/python-sandbox || {
    echo -e "${RED}❌ Failed to navigate to ~/prophecy/python-sandbox${NC}"
    return 1
  }
  echo -e "${GREEN}✅ Current directory: $(pwd)${NC}"
  
  # Get the git branch for image tagging
  local branch=$(git branch --show-current)
  local image_tag=$(echo "$branch" | sed 's/\//_/g')  # Replace slashes with underscores (SBT style)
  local registry="133450206866.dkr.ecr.us-west-1.amazonaws.com"
  local full_image="${registry}/sql_sandbox:${image_tag}"
  
  echo -e "${BLUE}🏷️  Image tag will be: ${image_tag}${NC}"
  echo -e "${BLUE}🖼️  Full image: ${full_image}${NC}"
  
  if [ "$skip_build" = true ]; then
    echo ""
    echo -e "${YELLOW}⏭️  Skipping build (--skip-build specified)${NC}"
  else
    # Step 2: ECR authentication
    echo ""
    echo -e "${BLUE}🔐 Step 2/5: Authenticating with ECR${NC}"
    aws ecr get-login-password --region us-west-1 | \
      docker login --username AWS --password-stdin \
      ${registry} || {
      echo -e "${RED}❌ ECR authentication failed${NC}"
      return 1
    }
    echo -e "${GREEN}✅ ECR authentication successful${NC}"
    
    # Step 3: Source version variables and build
    echo ""
    echo -e "${BLUE}🔧 Step 3/5: Setting up build environment${NC}"
    
    # Source version variables from Dependencies.scala
    export DEPENDENCIES_DOT_SCALA=~/prophecy/project/Dependencies.scala
    source ~/prophecy/x/setup_version_variables.sh
    
    echo "   sparkVersion: ${sparkVersion}"
    echo "   sparklibsVersion: ${sparklibsVersion}"
    echo "   prophecyUbuntuDockerBaseImageVersion: ${prophecyUbuntuDockerBaseImageVersion}"
    echo "   pythonComponentBuilderLibVersion: ${pythonComponentBuilderLibVersion}"
    echo "   pythonProphecyLibsVersion: ${pythonProphecyLibsVersion}"
    
    # Build inMemoryUCCatalog jar (required by SQL_Sandbox_Dockerfile)
    echo ""
    echo -e "${BLUE}🔨 Building inMemoryUCCatalog...${NC}"
    cd ~/prophecy
    sbt "inMemoryUCCatalog/package" || {
      echo -e "${RED}❌ inMemoryUCCatalog build failed${NC}"
      return 1
    }
    
    # Copy the jar to python-sandbox resources
    local jar_file=$(find "modules/scalaSandbox/inMemoryUnityCatalog/target/scala-2.12" -name "inmemoryuccatalog_2.12-*.jar" | head -n 1)
    if [ -z "$jar_file" ]; then
      echo -e "${RED}❌ inMemoryUCCatalog JAR not found${NC}"
      return 1
    fi
    cp "$jar_file" python-sandbox/resources/
    echo -e "${GREEN}✅ inMemoryUCCatalog built: $(basename $jar_file)${NC}"
    
    cd ~/prophecy/python-sandbox
    
    # Step 4: Build and push Docker image
    echo ""
    echo -e "${BLUE}🐳 Step 4/5: Building and pushing Docker image${NC}"
    
    # Download component builder libs (required by Dockerfile)
    echo -e "${BLUE}📦 Downloading component builder libs...${NC}"
    python3 scripts/download_all_libs.py --type jfrog_pypi --artifact ComponentBuilderPython --dest /tmp/prophecy_component_builder_libs 2>/dev/null || true
    rsync -av --ignore-existing /tmp/prophecy_component_builder_libs ./ 2>/dev/null || mkdir -p prophecy_component_builder_libs
    
    echo -e "${BLUE}🔨 Building Docker image...${NC}"
    
    # Always use cache bust timestamp to ensure fresh builds
    docker build \
      --build-arg "spark_type=with-spark" \
      --build-arg "spark_provider=apache" \
      --build-arg "sparkVersion=${sparkVersion}" \
      --build-arg "sparklibsVersion=${sparklibsVersion}" \
      --build-arg "prophecyUbuntuDockerBaseImageVersion=${prophecyUbuntuDockerBaseImageVersion}" \
      --build-arg "pythonComponentBuilderLibVersion=${pythonComponentBuilderLibVersion}" \
      --build-arg "pythonProphecyLibsVersion=${pythonProphecyLibsVersion}" \
      --build-arg "CACHE_BUST_FOR_PLIB=$(date +%s)" \
      --platform linux/amd64 \
      -t "${full_image}" \
      -f docker/SQL_Sandbox_Dockerfile . || {
      echo -e "${RED}❌ Docker build failed${NC}"
      return 1
    }
    echo -e "${GREEN}✅ Docker image built${NC}"
    
    echo -e "${BLUE}📤 Pushing Docker image...${NC}"
    docker push "${full_image}" || {
      echo -e "${RED}❌ Docker push failed${NC}"
      return 1
    }
    echo -e "${GREEN}✅ Docker image pushed: ${full_image}${NC}"
    
    # Cleanup the copied jar
    rm -f resources/inmemoryuccatalog*.jar
  fi
  
  # Step 5: Deploy to Kubernetes
  echo ""
  echo -e "${BLUE}☸️  Step 5/5: Deploying to Kubernetes${NC}"
  
  # Check if deployment exists
  local deployment_exists=$(kubectl get deployment ${deployment_name} -n ${namespace} 2>/dev/null)
  
  if [ -n "$deployment_exists" ]; then
    echo -e "${BLUE}🔄 Updating existing deployment...${NC}"
    kubectl set image deployment/${deployment_name} \
      ai-agent="${full_image}" \
      -n ${namespace} || {
      echo -e "${RED}❌ Failed to update deployment image${NC}"
      return 1
    }
  else
    echo -e "${BLUE}🆕 Creating new deployment...${NC}"
    
    # Create the deployment manifest
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${deployment_name}
  namespace: ${namespace}
  labels:
    app: ai-agent
    prophecy.io/component: ai-agent
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ai-agent
  template:
    metadata:
      labels:
        app: ai-agent
        prophecy.io/component: ai-agent
    spec:
      containers:
      - name: ai-agent
        image: ${full_image}
        imagePullPolicy: Always
        ports:
        - containerPort: 5001
          name: websocket
        - containerPort: 5002
          name: rest-api
        - containerPort: 9102
          name: sql-sandbox
        env:
        - name: LOG_LEVEL
          value: "INFO"
        - name: PYTHONUNBUFFERED
          value: "1"
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: ai-agent-secrets
              key: anthropic-api-key
              optional: true
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
          limits:
            cpu: "2"
            memory: "4Gi"
        volumeMounts:
        - name: workspace
          mountPath: /tmp/userCode
      volumes:
      - name: workspace
        emptyDir: {}
      imagePullSecrets:
      - name: prophecyregcred
---
apiVersion: v1
kind: Service
metadata:
  name: ${deployment_name}
  namespace: ${namespace}
  labels:
    app: ai-agent
spec:
  selector:
    app: ai-agent
  ports:
  - name: websocket
    port: 5001
    targetPort: 5001
  - name: rest-api
    port: 5002
    targetPort: 5002
  - name: sql-sandbox
    port: 9102
    targetPort: 9102
  type: ClusterIP
EOF
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}❌ Failed to create deployment${NC}"
      return 1
    fi
  fi
  
  echo -e "${GREEN}✅ Kubernetes resources applied${NC}"
  
  # Wait for rollout
  echo ""
  echo -e "${BLUE}⏳ Waiting for deployment rollout...${NC}"
  kubectl rollout status deployment/${deployment_name} -n ${namespace} --timeout=300s || {
    echo -e "${RED}❌ Deployment rollout failed or timed out${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Debugging commands:${NC}"
    echo "   kubectl get pods -n ${namespace} | grep ${deployment_name}"
    echo "   kubectl logs -n ${namespace} -l app=ai-agent --tail=50"
    echo "   kubectl describe pod -n ${namespace} -l app=ai-agent"
    return 1
  }
  
  # Verify pod is running
  echo ""
  echo -e "${BLUE}🔍 Verifying deployment...${NC}"
  local pod_name=$(kubectl get pods -n ${namespace} -l app=ai-agent -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  
  if [ -n "$pod_name" ]; then
    local ready=$(kubectl get pod "${pod_name}" -n ${namespace} \
      -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
    
    if [ "${ready}" = "True" ]; then
      echo -e "${GREEN}✅ Pod is ready: ${pod_name}${NC}"
    else
      echo -e "${YELLOW}⚠️  Pod is not ready yet: ${pod_name}${NC}"
    fi
  fi
  
  # Get the service cluster IP for configuring edweb
  local service_ip=$(kubectl get svc ${deployment_name} -n ${namespace} -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
  local agent_host="${deployment_name}.${namespace}.svc.cluster.local"
  
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  echo ""
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}✅ AI Agent deployment successful!${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${BLUE}📦 Image:     ${full_image}${NC}"
  echo -e "${BLUE}🌐 Service:   ${agent_host}:5001${NC}"
  echo -e "${BLUE}⏱️  Duration:  ${duration} seconds${NC}"
  echo -e "${BLUE}🕐 Completed: $(date)${NC}"
  echo ""
  echo -e "${CYAN}📝 To configure edweb to use this agent:${NC}"
  echo -e "${CYAN}   setagent${NC}"
  echo ""
  echo -e "${CYAN}📝 Or manually:${NC}"
  echo -e "${CYAN}   kubectl exec -n prophecy \$(kubectl get pod -n prophecy -o name | grep edweb | head -n 1) -- \\${NC}"
  echo -e "${CYAN}     curl --location 'localhost:9015/setAISandbox' \\${NC}"
  echo -e "${CYAN}     --header 'Content-Type: application/json' \\${NC}"
  echo -e "${CYAN}     --data '{\"host\":\"${agent_host}\",\"port\":5001}'${NC}"
  echo ""
  
  return 0
}

# Function: setagent - Configure edweb to use the deployed AI agent
# Usage: setagent [host] [port]
setagent() {
  local namespace="prophecy"
  local host="${1:-ai-agent.prophecy.svc.cluster.local}"
  local port="${2:-5001}"
  
  echo -e "${BLUE}🔧 Configuring edweb to use AI agent at ${host}:${port}${NC}"
  
  kubectl exec -n ${namespace} $(kubectl get pod -n ${namespace} -o name | grep edweb | head -n 1) -- \
    curl --silent --location 'localhost:9015/setAISandbox' \
    --header 'Content-Type: application/json' \
    --data "{\"host\":\"${host}\",\"port\":${port}}" || {
    echo -e "${RED}❌ Failed to configure edweb${NC}"
    return 1
  }
  
  echo ""
  echo -e "${GREEN}✅ edweb configured to use AI agent at ${host}:${port}${NC}"
  return 0
}

# Function: unsetagent - Clear AI agent configuration from edweb
unsetagent() {
  local namespace="prophecy"
  
  echo -e "${BLUE}🔧 Clearing AI agent configuration from edweb${NC}"
  
  kubectl exec -n ${namespace} $(kubectl get pod -n ${namespace} -o name | grep edweb | head -n 1) -- \
    curl --silent --location 'localhost:9015/setAISandbox' \
    --header 'Content-Type: application/json' \
    --data '{"host":""}' || {
    echo -e "${RED}❌ Failed to clear edweb configuration${NC}"
    return 1
  }
  
  echo ""
  echo -e "${GREEN}✅ AI agent configuration cleared from edweb${NC}"
  return 0
}

# Export functions if sourcing this file
# Note: In zsh, functions are automatically available once defined, no export needed
if [ -n "${BASH_VERSION}" ]; then
  # Bash - export functions
  export -f setpod 2>/dev/null
  export -f whatpods 2>/dev/null
  export -f letsed 2>/dev/null
  export -f letsco 2>/dev/null
  export -f letsgo 2>/dev/null
  export -f letsagent 2>/dev/null
  export -f setagent 2>/dev/null
  export -f unsetagent 2>/dev/null
  export -f pkdel 2>/dev/null
  export -f update_prophecy_image 2>/dev/null
  export -f verify_deployment 2>/dev/null
  export -f should_clean_build 2>/dev/null
  export -f save_build_state 2>/dev/null
fi
