#!/bin/bash
################################################################################
# NIST CSF Play 1: Asset Inventory and Classification - Execution Script
# 
# This script performs pre-flight checks and executes the asset inventory
# playbook with proper error handling and reporting.
#
# Usage:
#   ./run_play1.sh                    # Run against all hosts
#   ./run_play1.sh --limit production # Run against specific group
#   ./run_play1.sh --check            # Dry run
#   ./run_play1.sh --help             # Show help
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK="/home/ansible/NIST-CSF-SecurityAutomation/plays/play1_asset_inventory.yml"
INVENTORY="/home/ansible/NIST-CSF-SecurityAutomation/plays/inventory"
ANSIBLE_CFG="${SCRIPT_DIR}/ansible.cfg"
LOG_DIR="${SCRIPT_DIR}/logs"
REPORT_DIR="${SCRIPT_DIR}/inventory_reports"

# Timestamp for this run
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/play1_execution_${TIMESTAMP}.log"

################################################################################
# Helper Functions
################################################################################

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                    ║"
    echo "║           NIST CSF Play 1: Asset Inventory Execution               ║"
    echo "║                                                                    ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_FILE}"
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Execute NIST CSF Play 1: Asset Inventory and Classification

OPTIONS:
    --limit GROUP/HOST    Limit execution to specific group or host
    --check               Run in check mode (dry run)
    --tags TAGS           Run specific tags only
    --skip-tags TAGS      Skip specific tags
    --verbose, -v         Verbose output (-vvv for debug)
    --help, -h            Show this help message

EXAMPLES:
    $0                                          # Run against all hosts
    $0 --limit production                       # Run against production group
    $0 --limit web01.example.com               # Run against specific host
    $0 --check                                  # Dry run
    $0 --tags "gather_hardware,gather_software" # Run specific tasks
    $0 --skip-tags "gather_ports"              # Skip port scanning
    $0 -vvv                                    # Debug mode

NIST CSF CONTROLS:
    ID.AM-1  Physical devices and systems inventoried
    ID.AM-2  Software platforms and applications inventoried
    ID.AM-3  Communication and data flows mapped
    ID.AM-4  External information systems catalogued
    ID.AM-5  Resources prioritized based on criticality

EOF
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local all_checks_passed=true
    
    # Check if Ansible is installed
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible is not installed"
        echo "  Install with: pip3 install ansible"
        all_checks_passed=false
    else
        local ansible_version=$(ansible --version | head -n1)
        log_success "Ansible found: ${ansible_version}"
    fi
    
    # Check if playbook exists
    if [ ! -f "${PLAYBOOK}" ]; then
        log_error "Playbook not found: ${PLAYBOOK}"
        all_checks_passed=false
    else
        log_success "Playbook found: ${PLAYBOOK}"
    fi
    
    # Check if inventory exists
    if [ ! -f "${INVENTORY}" ]; then
        log_error "Inventory not found: ${INVENTORY}"
        all_checks_passed=false
    else
        log_success "Inventory found: ${INVENTORY}"
    fi
    
    # Check if ansible.cfg exists
    if [ ! -f "${ANSIBLE_CFG}" ]; then
        log_warning "ansible.cfg not found: ${ANSIBLE_CFG}"
    else
        log_success "Configuration found: ${ANSIBLE_CFG}"
    fi
    
    # Create necessary directories
    for dir in "${LOG_DIR}" "${REPORT_DIR}" "${SCRIPT_DIR}/fact_cache" "${SCRIPT_DIR}/retry"; do
        if [ ! -d "${dir}" ]; then
            mkdir -p "${dir}"
            log_info "Created directory: ${dir}"
        fi
    done
    
    if [ "$all_checks_passed" = false ]; then
        log_error "Prerequisites check failed. Please resolve the issues above."
        exit 1
    fi
    
    log_success "All prerequisite checks passed"
}

validate_inventory() {
    log_info "Validating inventory..."
    
    if ansible-inventory --list -i "${INVENTORY}" > /dev/null 2>&1; then
        log_success "Inventory validation passed"
        
        # Show inventory summary
        local host_count=$(ansible-inventory --list -i "${INVENTORY}" | jq '.["_meta"]["hostvars"] | length')
        log_info "Total hosts in inventory: ${host_count}"
    else
        log_error "Inventory validation failed"
        exit 1
    fi
}

test_connectivity() {
    log_info "Testing connectivity to hosts..."
    
    local limit_arg=""
    if [ ! -z "${LIMIT_HOSTS}" ]; then
        limit_arg="--limit ${LIMIT_HOSTS}"
    fi
    
    if ansible all -i "${INVENTORY}" ${limit_arg} -m ping -o 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "Connectivity test passed"
    else
        log_warning "Some hosts are unreachable. Continue? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Execution cancelled by user"
            exit 0
        fi
    fi
}

run_playbook() {
    log_info "Starting playbook execution..."
    log_info "Execution log: ${LOG_FILE}"
    
    # Build ansible-playbook command
    local cmd="ansible-playbook"
    cmd="${cmd} -i ${INVENTORY}"
    cmd="${cmd} ${PLAYBOOK}"
    
    # Add optional arguments
    [ ! -z "${LIMIT_HOSTS}" ] && cmd="${cmd} --limit ${LIMIT_HOSTS}"
    [ ! -z "${CHECK_MODE}" ] && cmd="${cmd} --check"
    [ ! -z "${TAGS}" ] && cmd="${cmd} --tags ${TAGS}"
    [ ! -z "${SKIP_TAGS}" ] && cmd="${cmd} --skip-tags ${SKIP_TAGS}"
    [ ! -z "${VERBOSE}" ] && cmd="${cmd} ${VERBOSE}"
    
    log_info "Executing: ${cmd}"
    echo "----------------------------------------" >> "${LOG_FILE}"
    
    # Execute playbook
    if eval "${cmd}" 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "Playbook execution completed successfully"
        return 0
    else
        log_error "Playbook execution failed"
        return 1
    fi
}

generate_summary() {
    log_info "Generating execution summary..."
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Execution Summary                             ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
    
    # Count inventory files generated
    local json_count=$(find "${REPORT_DIR}" -name "*${TIMESTAMP:0:8}*.json" 2>/dev/null | wc -l)
    local yml_count=$(find "${REPORT_DIR}" -name "*${TIMESTAMP:0:8}*.yml" 2>/dev/null | wc -l)
    
    echo -e "${BLUE}║${NC}  Inventory Reports Generated: ${json_count} JSON, ${yml_count} YAML"
    echo -e "${BLUE}║${NC}  Report Location: ${REPORT_DIR}"
    echo -e "${BLUE}║${NC}  Execution Log: ${LOG_FILE}"
    echo -e "${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  NIST CSF Controls Addressed:"
    echo -e "${BLUE}║${NC}    ✓ ID.AM-1: Physical devices inventoried"
    echo -e "${BLUE}║${NC}    ✓ ID.AM-2: Software platforms inventoried"
    echo -e "${BLUE}║${NC}    ✓ ID.AM-3: Communication flows mapped"
    echo -e "${BLUE}║${NC}    ✓ ID.AM-4: External systems catalogued"
    echo -e "${BLUE}║${NC}    ✓ ID.AM-5: Resources prioritized by criticality"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Show latest reports
    if [ ${json_count} -gt 0 ]; then
        log_info "Latest inventory reports:"
        find "${REPORT_DIR}" -name "*${TIMESTAMP:0:8}*.json" 2>/dev/null | head -5 | while read -r file; do
            echo "  - $(basename ${file})"
        done
    fi
}

cleanup_old_reports() {
    log_info "Cleaning up old reports (keeping last 30 days)..."
    
    # Delete reports older than 30 days
    find "${REPORT_DIR}" -name "*.json" -type f -mtime +30 -delete 2>/dev/null || true
    find "${REPORT_DIR}" -name "*.yml" -type f -mtime +30 -delete 2>/dev/null || true
    find "${LOG_DIR}" -name "*.log" -type f -mtime +30 -delete 2>/dev/null || true
    
    log_success "Cleanup completed"
}

################################################################################
# Main Script
################################################################################

main() {
    # Initialize variables
    LIMIT_HOSTS=""
    CHECK_MODE=""
    TAGS=""
    SKIP_TAGS=""
    VERBOSE=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --limit)
                LIMIT_HOSTS="$2"
                shift 2
                ;;
            --check)
                CHECK_MODE="--check"
                shift
                ;;
            --tags)
                TAGS="$2"
                shift 2
                ;;
            --skip-tags)
                SKIP_TAGS="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE="-v"
                shift
                ;;
            -vv)
                VERBOSE="-vv"
                shift
                ;;
            -vvv)
                VERBOSE="-vvv"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Create log file
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    
    print_banner
    
    log_info "Execution started at: $(date)"
    log_info "Script directory: ${SCRIPT_DIR}"
    
    # Run pre-flight checks
    check_prerequisites
    validate_inventory
    test_connectivity
    
    # Execute playbook
    if run_playbook; then
        EXECUTION_STATUS=0
        generate_summary
        cleanup_old_reports
        
        log_success "All tasks completed successfully!"
        echo ""
        log_info "Next steps:"
        echo "  1. Review inventory reports in: ${REPORT_DIR}"
        echo "  2. Generate compliance report: python3 nist_csf_report_generator.py"
        echo "  3. Proceed to Play 2: Vulnerability Assessment"
        echo ""
    else
        EXECUTION_STATUS=1
        log_error "Execution completed with errors. Check log: ${LOG_FILE}"
        echo ""
        log_info "Troubleshooting:"
        echo "  1. Check the log file for detailed errors"
        echo "  2. Verify host connectivity: ansible all -m ping"
        echo "  3. Test with check mode: $0 --check"
        echo "  4. Run with verbose mode: $0 -vvv"
        echo ""
    fi
    
    exit ${EXECUTION_STATUS}
}

# Execute main function
main "$@"
