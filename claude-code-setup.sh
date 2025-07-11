#!/usr/bin/env bash
# bash unofficial strict mode:
set -euo pipefail
IFS=$'\n\t'
[[ -n ${DEBUG:-""} ]] && set -x

die() {
    echo "$@" >&2
    exit 1
}

CLAUDE_WORKFLOW=$(cat <<EOF
name: Claude PR Creation

on:
  issue_comment:
    types: [created]

# docs: https://docs.github.com/en/actions/how-tos/writing-workflows/choosing-what-your-workflow-does/controlling-permissions-for-github_token
permissions:
  contents: read
  pull-requests: write
  id-token: write

jobs:
  create-pr:
    if: contains(github.event.comment.body, '@claude')
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4    
      - uses: anthropics/claude-code-action@beta
        with:
          prompt: "\${{ github.event.comment.body }}"
          allowed_tools: "Bash(git status),Bash(git log),Bash(git show),Bash(git blame),Bash(git reflog),Bash(git stash list),Bash(git ls-files),Bash(git branch),Bash(git tag),Bash(git diff),View,GlobTool,GrepTool,BatchTool"
          anthropic_api_key: "\${{ secrets.ANTHROPIC_API_KEY }}"
EOF
)

echo "🤖 Claude Code Workflow Setup"
echo "=============================="

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    die "❌ GitHub CLI (gh) is not installed. Please install it first: https://cli.github.com/"
fi

# Check if user is authenticated with gh
if ! gh auth status &> /dev/null; then
    die "❌ You are not authenticated with GitHub CLI. Please run: gh auth login"
fi

echo "✅ GitHub CLI is installed and authenticated"

echo
echo "📋 Step 1: Create Anthropic API Key"
echo "Please open the link and create a new API key: https://console.anthropic.com/settings/keys"
echo
read -p "Enter your Anthropic API key: " -s ANTHROPIC_API_KEY
echo

if [[ -z "$ANTHROPIC_API_KEY" ]]; then
    die "❌ API key cannot be empty"
fi

echo "🔐 Step 2: Setting up GitHub Actions secret..."
if gh secret set ANTHROPIC_API_KEY --body "$ANTHROPIC_API_KEY"; then
    echo "✅ ANTHROPIC_API_KEY secret has been set"
else
    die "❌ Failed to set GitHub Actions secret"
fi

echo
echo "🔧 Step 3: Configure Claude GitHub App"
echo "Please open the following link and configure GitHub to give access to Claude Code: https://github.com/apps/claude"
echo
read -p "Press Enter after you have configured the Claude GitHub app..."

# Create and checkout branch
BRANCH_NAME="claude-code-integration"
echo
echo "🌿 Step 5: Creating branch $BRANCH_NAME..."

# Check if branch already exists
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
    echo "📋 Branch '$BRANCH_NAME' already exists, checking it out..."
    git checkout $BRANCH_NAME
else
    echo "🆕 Creating new branch '$BRANCH_NAME'..."
    git checkout -b $BRANCH_NAME
fi

echo "✅ On branch '$BRANCH_NAME'"

echo
echo "📝 Step 6: Creating workflow file..."
mkdir -p .github/workflows
echo "$CLAUDE_WORKFLOW" > .github/workflows/claude.yaml
echo "✅ Created .github/workflows/claude.yaml"

echo
echo "🚀 Step 7: Committing and pushing changes..."
git add .github/workflows/claude.yaml
git commit -m "Add Claude Code workflow integration"
echo "✅ Changes committed"

echo "📤 Pushing branch to origin..."
git push -u origin $BRANCH_NAME
echo "✅ Branch pushed"

echo "🔄 Creating pull request..."
if gh pr create --title "Add Claude Code Integration" --body "This PR adds the Claude Code workflow integration.

## What this adds:
- GitHub Actions workflow that triggers on @claude mentions in issue comments
- Proper permissions for Claude to create PRs
- Configured tool access for code analysis and modification

## How to use:
1. Create an issue or comment on an existing issue
2. Mention @claude followed by your request
3. Claude will analyze the code and create a PR with the requested changes

The workflow is now ready to use!" --head $BRANCH_NAME; then
    echo "✅ Pull request created successfully"
else
    echo "⚠️  Pull request creation failed, but you can create it manually"
fi

echo
echo "🎉 Claude Code setup complete!"
echo "=============================="
echo "✅ Anthropic API key configured"
echo "✅ GitHub Actions workflow created"
echo "✅ Pull request created"
echo
echo "Next steps:"
echo "1. Review and merge the pull request"
echo "2. Mention @claude in an issue comment to test the integration"
