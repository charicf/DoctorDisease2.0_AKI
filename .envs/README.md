The example mimic env file serves as a guide of what the file should look like. Basically it needs to contain:
```
PHYSIONET_USER=<username_goes_here>
PHYSIONET_PASSWORD=<password_goes_here_between_quotations>
```
The password should be between quotations so that it does not get character escaped by mistake.

***IMPORTANT***: Make sure to rename the file to 'mimic.env' and double check you are **NOT** commiting the file to the repo (if the name is correct it should be ignored by .gitignore), so your password does not get leaked.
