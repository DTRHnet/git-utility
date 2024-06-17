─$ cat git-utility.sh
#!/usr/bin/env bash
#
# git-utility.sh - Basic script to create a new GitHub repo based on the variables below. Simplifies
#                  the process and takes a second or two to initialize remote and local repositories.
#
#  >  https://dtrh.net
#  >  KBS  < admin [at] dtrh.net >

# Initialize Variables ----------------------------
REPO_DESCRIPTION=""
GITHUB_API_URL="https://api.github.com/user/repos"
ACCESS_TOKEN=""
VERBOSE=0
DRY_RUN=0
LOG_FILE=""
TERMUX=0
BANNER="\
  ____  ____  ______         __ __  ______  ____  _      ____  ______  __ __
 /    ||    ||      |       |  |  ||      ||    || |    |    ||      ||  |  |
|   __| |  | |      | _____ |  |  ||      | |  | | |     |  | |      ||  |  |
|  |  | |  | |_|  |_||     ||  |  ||_|  |_| |  | | |___  |  | |_|  |_||  ~  |
|  |_ | |  |   |  |  |_____||  :  |  |  |   |  | |     | |  |   |  |  |___, |
|     | |  |   |  |         |     |  |  |   |  | |     | |  |   |  |  |     |
|___,_||____|  |__|          \__,_|  |__|  |____||_____||____|  |__|  |____/

[ KBS < admin \[AT\] dtrh.net ]                                             .
"

CONFIG_FILE="git-utility.conf"

# Default configuration
DEFAULT_CONFIG='{
  "GITHUB_USERNAME": "", 
  "GITHUB_EMAIL": "",
  "GITHUB_REPO": "",
  "REPO_DESCRIPTION": "",
  "ACCESS_TOKEN": "",
  "VERBOSE": 0,
  "DRY_RUN": 0,
  "LOG_FILE": "",
  "TERMUX": 0
}'

# List of valid configuration variables
VALID_VARIABLES=("GITHUB_USERNAME" "GITHUB_EMAIL" "GITHUB_REPO" "REPO_DESCRIPTION" "ACCESS_TOKEN" "VERBOSE" "DRY_RUN" "LOG_FILE" "TERMUX")

function print_config() {
   jq . "$CONFIG_FILE"
}

function center_text() {
    local text="$1"
    local terminal_width=$(tput cols)
    local text_length=${#text}
    local padding=$(( (terminal_width - text_length) / 2 ))

    # Ensure padding is not negative
    if (( padding < 0 )); then
        padding=0
    fi

    printf "%*s%s\n" $padding "" "$text"
}

function is_termux() {
    if [ -d "$PREFIX" ] && [ -x "$(command -v termux-info)" ]; then
        TERMUX=1
    else
        TERMUX=0
    fi
}

function banner() {
    is_termux
    while IFS= read -r line; do
        center_text "$line"
    done <<< "$BANNER"
    check_config_integrity
    load_config
}

function help() {
    echo "Usage: git-utility.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo " "
    echo "  Script Options:"
    echo "    -v, --verbose                 Enable verbose mode"
    echo "    -h, --help                    Display this help message"
    echo "    -l, --log [file]              Log verbose to [file]"
    echo " "
    echo "  Github Operations:"
    echo "    -s, --status [repo]           Check the status of a repository"
    echo "    -n, --new-repo [repo]         Create a new GitHub repository"
    echo "    -c, --clone-repo [repo]       Clone an existing GitHub repository"
    echo "    -r, --remove-repo [repo]      Delete a GitHub repository"
    echo " "
    echo "  Configuration:"
    echo "    -C, --config [file]           Load config file from [file]" 
    echo "    -g, --get                     Display all variables in current configuration"
    echo "    -G, --getvar [var] [value]    Retrieve value of variable in current config"
    echo "    -S, --setvar [var] [value]    Set a configuration variable"
    echo " "
    echo "  --dry-run                       Show what would be done without making any changes"

    echo ""
    echo ""
}

function verbose() {
    if [ $VERBOSE -eq 1 ]; then
        echo "$1"
    fi
}

function check_GITHUB_REPO() {
    if [ -z "$GITHUB_REPO" ]; then
        echo "Error: Repository name is required but not provided." >&2
        exit 1
    fi
}

function newRepo() {
    check_GITHUB_REPO
    if [ $DRY_RUN -eq 1 ]; then
        echo "DRY-RUN: Would create repository $GITHUB_REPO on GitHub."
        echo "DRY-RUN: Would initialize local repository."
        echo "DRY-RUN: Would add README.md to local repository."
        echo "DRY-RUN: Would add and commit initial files."
        echo "DRY-RUN: Would add remote origin and push to GitHub."
        return
    fi

    verbose "Creating repository $GITHUB_REPO on GitHub..."
    curl -H "Authorization: token $ACCESS_TOKEN" \
         -d "{\"name\":\"$GITHUB_REPO\", \"description\":\"$REPO_DESCRIPTION\", \"private\":false}" \
         $GITHUB_API_URL

    if [ $? -ne 0 ]; then
        echo "Error: Failed to create repository on GitHub." >&2
        exit 1
    fi

    verbose "Initializing local repository..."
    mkdir "$GITHUB_REPO"
    cd "$GITHUB_REPO" || exit
    git init

    verbose "Adding README.md to local repository..."
    echo "# $GITHUB_REPO" > README.md
    echo "" >> README.md
    echo "$REPO_DESCRIPTION" >> README.md

    verbose "Adding and committing initial files..."
    git add README.md
    git commit -m "Initial commit"

    verbose "Adding remote origin and pushing to GitHub..."
    git remote add origin "https://$GITHUB_USERNAME:$ACCESS_TOKEN@github.com/$GITHUB_USERNAME/$GITHUB_REPO.git"
    git push -u origin master

    echo "Repository $GITHUB_REPO created and initial commit pushed to GitHub."
}

function cloneRepo() {
    check_GITHUB_REPO
    if [ $DRY_RUN -eq 1 ]; then
        echo "DRY-RUN: Would clone repository $GITHUB_REPO from GitHub."
        return
    fi

    verbose "Cloning repository $GITHUB_REPO from GitHub..."
    git clone "https://$GITHUB_USERNAME:$ACCESS_TOKEN@github.com/$GITHUB_USERNAME/$GITHUB_REPO.git"
}

function removeRepo() {
    check_GITHUB_REPO
    if [ $DRY_RUN -eq 1 ]; then
        echo "DRY-RUN: Would delete repository $GITHUB_REPO from GitHub."
        return
    fi

    verbose "Deleting repository $GITHUB_REPO from GitHub..."
    curl -X DELETE -H "Authorization: token $ACCESS_TOKEN" \
         "https://api.github.com/repos/$GITHUB_USERNAME/$GITHUB_REPO"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to delete repository on GitHub." >&2
        exit 1
    fi

    echo "Repository $GITHUB_REPO deleted from GitHub."
}

function checkStatus() {
    if [ $DRY_RUN -eq 1 ]; then
        echo "DRY-RUN: Would check status of local repository."
        return
    fi

    verbose "Checking status of local repository..."
    git status
}

# Create default config if not exists
function create_default_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$DEFAULT_CONFIG" > "$CONFIG_FILE"
        echo "Default configuration created."
    fi
}

# Load configuration from JSON file
function load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        eval "$(jq -r 'to_entries | .[] | "\(.key)=\(.value)"' "$CONFIG_FILE")"
        [ ! x ] && x=1 || echo -e "Configuration loaded successfully. \n"
    else
        echo "Configuration file not found. Creating a new one."
        create_default_config
    fi
}

# Update configuration in JSON file
function update_config() {
    local key="$1"
    local value="$2"
    
    # Check if the variable is valid
    if [[ ! " ${VALID_VARIABLES[@]} " =~ " ${key} " ]]; then
        echo "Error: Invalid variable name '$key'."
        echo "Valid variables are: ${VALID_VARIABLES[*]}"
        exit 1
    fi

    jq --arg key "$key" --arg value "$value" \
       'if $value | test("^[0-9]+$") then .[$key] |= ($value | tonumber) else .[$key] |= $value end' \
       "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "Configuration updated successfully."
}

# Check configuration file integrity
function check_config_integrity() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file not found. Creating a new one."
        create_default_config
        return
    fi

    local missing_keys=()
    for key in "${VALID_VARIABLES[@]}"; do
        if ! jq -e ".\"$key\"" "$CONFIG_FILE" > /dev/null; then
            missing_keys+=("$key")
        fi
    done

    if [ ${#missing_keys[@]} -ne 0 ]; then
        echo "Error: The following keys are missing from the configuration file: ${missing_keys[*]}"
        echo "Recreating the configuration file with default values."
        create_default_config
    else
        echo "Configuration file integrity check passed."
    fi
}

# Parse arguments
while (( "$#" )); do
    case "$1" in
        -v | --verbose ) VERBOSE=1; shift ;;
        -h | --help ) help; exit 0 ;;
        -n | --new-repo )
            ACTION="newRepo"
            if [ -n "$2" ]; then
                GITHUB_REPO=$2
                shift 2
            else
                shift
            fi
            ;;
        -c | --clone-repo )
            ACTION="cloneRepo"
            if [ -n "$2" ]; then
                GITHUB_REPO=$2
                shift 2
            else
                shift
            fi
            ;;
        -r | --remove-repo )
            ACTION="removeRepo"
            if [ -n "$2" ]; then
                GITHUB_REPO=$2
                shift 2
            else
                shift
            fi
            ;;
        -s | --status ) ACTION="checkStatus"; shift ;;
        -g | --get ) ACTION="print_config"; shift ;;
        --dry-run ) DRY_RUN=1; shift ;;
        -S | --setvar )
            if [ -n "$2" ] && [ -n "$4" ]; then
                update_config "$2" "$4"
                exit 0
            else
                echo "Error: Invalid arguments for setvar. Usage: setvar [variable] [value]" >&2
                exit 1
            fi
            ;;
        -- ) shift; break ;;
        * ) break ;;
    esac
done

main() {

    banner
    
    if [ -n "$ACTION" ]; then
        if [ "$ACTION" == "newRepo" ] || [ "$ACTION" == "cloneRepo" ] || [ "$ACTION" == "removeRepo" ]; then
            check_GITHUB_REPO
        fi
        $ACTION
    else
        echo "No action specified. Use -h or --help for usage information."
        exit 1
    fi
}

main "$@"
