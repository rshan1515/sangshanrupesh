# Secure Repository Checklist

Use this checklist to help ensure your repository follows best security practices!

## Repository Access
- [ ] Review repository collaborators and teams regularly
- [ ] Remove unnecessary access (least privilege principle)
- [ ] Enable 2FA for all collaborators

## Branch Protection
- [ ] Protect main/master branch (require PRs for changes)
- [ ] Enable required status checks before merging
- [ ] Enable required reviews before merging

## Secrets Management
- [ ] Do not commit secrets (API keys, tokens, passwords)
- [ ] Use GitHub Secrets for workflows (Actions)
- [ ] Audit repository for accidentally committed secrets

## Dependency Security
- [ ] Enable Dependabot alerts and updates
- [ ] Regularly update dependencies
- [ ] Audit for vulnerable dependencies

## GitHub Actions
- [ ] Use actions from trusted sources only
- [ ] Pin action versions (not just @latest)
- [ ] Review workflow permissions

## Code Quality
- [ ] Use linting and formatting tools
- [ ] Run tests on all PRs

## Repository Settings
- [ ] Enable security advisories
- [ ] Enable private vulnerability reporting
- [ ] Set a security policy (SECURITY.md)

## Documentation
- [ ] Provide clear contributing guidelines
- [ ] Document responsible disclosure process

## Miscellaneous
- [ ] Monitor for suspicious activity
- [ ] Backup critical data

---

_Review this checklist regularly and update as needed!_