# Backups

CodeOcean persists most data in the PostgreSQL database including submissions and the respective user files. Only binary files that cannot be serialized are stored in the `public/uploads` folder in dedicated sub-folders with the ID as folder name. Necessary files are temporarily extracted to the container's file system during execution but don't need to backed up separately.

## Summary

In order to back up CodeOcean, you should consider these locations:

- `config/*.yml` and `config/*.yml.erb`
- The values of [environment variables](environment_variables.md) set for the web server
- PostgreSQL database as specified in `config/database.yml`
- `public/uploads` and all sub-folders
