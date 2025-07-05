# CONTRIBUTING

The best and most direct way to contribute to the mod's programming is by issuing a pull request. Generally, pull requests are best done by forking the mod's code, committing and pushing to your fork, and then issuing a pull request from your repository. It is not the best idea to use GitHub directly for editing, since if you need to make many edits, it will spam email inboxes.

When it comes to code cleanliness, the code standards appear to have been different between the base Unreal engine, vanilla SWAT 4 and vanilla TSS. Specifically:

 * The base Unreal engine does not support the use of the `#ifdef` keyword; this would appear to be a modified version of the engine which supports it.
 * The Stetchkov Syndicate uses spaces instead of tabs for indentation.

That being said, I would like to adhere to these standards as much as possible:

 * Use tabs instead of spaces for indentation. Use spaces instead of tabs when aligning comments across multiple lines.
 * Braces should always be used for `replication`, `while`, `if`/`else`/`else if` (except in replication blocks, where it is illegal), `for`, `defaultproperties`, `state` and any other blocks.
 * Braces should be on their own line. For example:

```java
if(something) { // bad

if(something)
{ // good
```

 * Class names (and `Object`) should start with a capital letter. (UnrealScript is not case sensitive)
 * Class properties should start with a capital letter. Local variables can start with either a lowercase or capital letter. Boolean variables should always start with a lowercase "b"
 * Primitive types (`string`, `int`, etc) should start with a lowercase letter.
 * Reserved words (`local`, `replication`, `if`, etc) should start with a lowercase letter.
 * Functions should start with a capital letter and be written as a verb. `Name` is a bad name for a function, but `GetName()` and `SetName()` are good.
 * Do not use `#ifdef` as support for it is spotty on some text editors which have UnrealScript support.
 * Use `const` whenever possible.
 * Only use `out` variables when it is not possible to use a return value.
 * Use `simulated` on functions that are executed both on the client and server.
 * Don't write both getter and setter functions for private variables unless there is a side effect involved in doing either. Instead, use a public variable. For example:

```java
var public bool bMyVariable;
var private bool bMyBadlyUsedVariable;

function bool GetMyBadlyUsedVariable()
{
	return bMyBadlyUsedVariable;
}

function SetMyBadlyUsedVariable(bool bNewValue)
{
	bMyBadlyUsedVariable = bNewValue;
}
```

Assets have to be sent to myself personally to integrate into the mod. Check out our Discord server if you haven't already!