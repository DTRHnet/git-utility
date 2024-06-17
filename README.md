# git-utility.sh

`git-utility.sh` is a basic bash script designed to simplify the process of creating and managing GitHub repositories. It initializes remote and local repositories within seconds. The script also includes additional functionalities like cloning, deleting repositories, and checking the status of local repositories.

## Installation

1. Clone this repository or download the script directly.
2. Make sure you have the required permissions to execute the script.

```bash
chmod +x git-utility.sh
```

3. Ensure you have `jq` installed for JSON processing. Install it using your package manager if necessary.

## Usage

Run the script with appropriate options as per your requirements.

```bash
./git-utility.sh [OPTIONS]
```

## Configuration

The script uses a configuration file (`git-utility.conf`) to store user-specific settings. A default configuration file will be created if one does not exist. 
You can use --setvar to set variable values, or edit the configuration file directly.

### Default Configuration

```json
{
  "GITHUB_USERNAME": "",
  "GITHUB_EMAIL": "",
  "GITHUB_REPO": "",
  "REPO_DESCRIPTION": "",
  "ACCESS_TOKEN": "",
  "VERBOSE": 0,
  "DRY_RUN": 0,
  "LOG_FILE": "",
  "TERMUX": 0
}
```
## Options

```bash
Usage: git-utility.sh [OPTIONS]

Options:

  Script Options:
    -v, --verbose                 Enable verbose mode
    -h, --help                    Display this help message
    -l, --log [file]              Log verbose to [file]

  Github Operations:
    -s, --status [repo]           Check the status of a repository
    -n, --new-repo [repo]         Create a new GitHub repository
    -c, --clone-repo [repo]       Clone an existing GitHub repository
    -r, --remove-repo [repo]      Delete a GitHub repository

  Configuration:
    -C, --config [file]           Load config file from [file]
    -g, --get                     Display all variables in current configuration
    -G, --getvar [var] [value]    Retrieve value of variable in current config
    -S, --setvar [var] [value]    Set a configuration variable

  --dry-run                       Show what would be done without making any changes
```

## Functions

### Main Functions

- `newRepo`: Creates a new GitHub repository and initializes a local repository.
- `cloneRepo`: Clones an existing GitHub repository.
- `removeRepo`: Deletes a specified GitHub repository.
- `checkStatus`: Checks the status of the local repository.

## License

This script is open-source and available under the MIT License. See the LICENSE file for more information.

---

For more information, visit [https://dtrh.net](https://dtrh.net) or contact admin[at]dtrh.net.
