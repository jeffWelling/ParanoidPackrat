Perhaps with an additional, optional debug argument which suppresses the raise, for the purpose of assisting development and testing on systems where the backupDestinations are known to not exist because its a development environment.  Such as developing on one machine, but running it on another.
