# claude-code-setup.sh

An easy way to set up Claude Code integration and then invite **`@claude`** in issue comments to do the coding.

## Setup

1. Make sure you have [gh](https://cli.github.com/) installed and authenticated.

2. Clone this repo, then go to your working copy and run the script:

```bash
git clone git@github.com:haron/claude-code-setup.sh.git
cd my-project
../claude-code-setup.sh/claude-code-setup.sh
```

The script will:
1. Guide you through creating an Anthropic API key
2. Set up GitHub Actions secrets
3. Configure the Claude GitHub App
4. Create the workflow file
5. Create a pull request with the integration.
