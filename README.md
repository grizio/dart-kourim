# Kourim

A simple ORM to be used to fetch and send data with ajax and cache them on browser local storages.

The objective of this system is to provide a simple mean for the developer to query a server and transform the raw result into dart classes and do the contrary (model to raw) to send to a server.

For the moment, only JSON is accepted.

## First step: Prepare your model

For our example, we only use a single class with some queries.
Comments on model explained themselves how the configuration works.

**Note**:
You will find some constants in `'package:kourim/constants.dart'` which will be prefixed as `constants` in this documentation.
Using these constants provides you a compile-time checking for all specific key words.

```dart

    // The class User is a model named "user" and have a cache into IndexedDB browser.
    // When a query does not have a remote query, all rows will be fetched by using the constants.findAll query.
    @model(name: 'user', storage: constants.indexedDB, strategy: constants.table, limit: 3600)
    
    // constants.findAll will be used to fetch all data on server and save them into model cache.
    // The query constants.find will be called after the call of this query.
    @query(name: constants.findAll, remote: '/users', strategy: constants.column, then: constants.find)
    
    // constants.find will be used to fetch one row on server and save it into model cache.
    @query(name: constants.find, remote: '/user/:id', strategy: constants.row)
    
    // "search" provides the developer a query to fetch data from model cache directly.
    // Because of how the system works, there is no need for different queries to fetch data from model cache.
    @query(name: 'search', strategy: constants.rows)
    
    // "userpost" will send a POST request to the server and returning any result.
    @query(name: 'userpost', remote: '/userpost', type: constants.post, strategy: constants.none)
    class User {
      @column()
      @key()
      int id; // primary key column
    
      @column()
      @onQuery('userpost')
      String username; // username column, used by "userpost" query
    
      @column()
      @onQuery('userpost')
      String email; // email column, used by "userpost" query
    
      @column()
      @onQuery('userpost')
      String birthday; // birthday column as String (conversion is in progress), used by "userpost" query
    
      @column()
      String password; // password column, not used by "userpost" query
    }
```

## Second step: Prepare your application

In the main method, you need to prepare the application to be used by kourim system.
We advise you to create your own method of configuration and call it from main.

```dart

    import 'package:kourim/kourim.dart' as kourim;
    import 'package:kourim/config.dart' as kourimConfig;
    import 'user.dart'; // your previous model
    import 'dart:indexed_db' as idb;

    /// Entry point of your application
    void main() {
        configureKourim();
        configureIDB();
        launch(); // See next part for this function.
    }
    
    /// Main configuration of kourim.
    void configureKourim();
        kourimConfig.appName = 'My application name';
        kourimConfig.databaseName = 'myappdb';
        
        // Host prefix for all yours queries.
        // For instance, the "userpost" remote url will be "http://localhost/projects/example/userpost"
        kourimConfig.remoteHost = 'http://localhost/projects/example';
    }
    
    /// Configures the IndexedDB browser database.
    void configureIDB() {
        /// Kourim system provides a sample mean to add version controls.
        /// Note: the final version of IndexedDB will be the maximal one given by calling onChange
        kourim.database.onChange(1, (idb.VersionChangeEvent event) {
            idb.Database db = (event.target as idb.Request).result;
            // Store for our model "user"
            var userStore = db.createObjectStore('user', keyPath: 'id');
        });
        kourim.database.onChange(2, (idb.VersionChangeEvent event) {
            // Other operation
        });
    }
```

## Last step: Query the server

When the system is configured and ready, we can use it to query on server.
Below two different examples of requests, one to fetch and filter data and the other to send data to server.

```dart
    
    /// Do your business
    void launch() {
        // By calling kourim.prepare(), the system will be initialized.
        // Each time you need to use kourim, you must call kourim.prepare or reuse the Future returned by this method
        // (no change, because initialisation is done only one time)
        kourim.prepare().then((_){
            // We get the entity manager
            var em = kourim.entityManager;
            
            // Note: the two request are executed one the same time, so the second one can be completed before the first one.
            
            // We want to execute a search on all users in terms of given constraint.
            // The system will fetch all rows of user (as seen into User configuration)
            // only the first time (and after cache expiration).
            em.createQuery('user', 'search').then((qb){
                qb.setConstraint((User user) => user.email.length > 5);
                qb.execute().then((users){
                    // We show user - users are a List<User>
                    window.console.debug(users);
                });
            });
            
            // We want to send a remote request with the user in parameter, but only configured fields
            // (username, email, birthday) as seen into User configuration.
            em.createQuery('user', 'tstpost').then((qb){
                var user = new User();
                user.id = 1; // not send to server
                user.username = 'my test';
                user.email = 'my@test.com';
                user.birthday = '2000-01-01';
                qb.addInputEntity(user);
                qb.execute().then((_){
                    // The query returns nothing, because strategy is none.
                    // So the next line will display null.
                    window.console.debug(_);
                });
            });
        });
    }
```


## What's next?

For the moment, it is all for the documentation, I hope it will be sufficient to you to test it.

For next features, I will implement these one:

### Type conversion and nested objects

For the moment, only `int` ans `string` types are usable with the system.
I will implement a mean to use complex objects with classic one implemented by default (eg: `Datetime`).

The system cannot use nested objects. As the same idea as type conversion, I hope to implement nested this feature quickly.
Nested objects are an object existing into the fetched data from or to server, not a foreign key which is the following feature.

### Foreign keys

Like an ORM, I want to implement a foreign key and join system to query complex objects.

## How to improve the system

First of all, you can send your feedback. It will help me to understand your needs and yours wishes.

Secondly, you can clone the project and update it all you want.

Thirdly, we can work together to develop future works.