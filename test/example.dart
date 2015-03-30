library kourim.test.example;

class Article {
  int id;
  String canonical;
  String title;
  String content;
  DateTime date;

  Article(this.id, this.canonical, this.title, this.content, this.date);
}

class Comment {
  int id;
  String title;
  String content;
  DateTime date;

  Comment(this.id, this.title, this.content, this.date);
}

@Injectable()
class TableArticle extends FullCachedTable<Article> {
  var id = key('id');
  var canonical = column('canonical', unique: true);
  var title = column('title');
  var content = column('content');
  var date = column('date', type: constants.date);

  @override
  Article fromJson(Map<String, Object> data) => new Article(data['id'], data['canonical'], data['title'], data['content'], toDate(data['date']));

  @override
  Map<String, Object> toJson(Article article) => {
    'id': article.id,
    'canonical': article.canonical,
    'title': article.title,
    'content': article.title,
    'date': fromDate(article.date)
  };

  TableArticle(@indexedDb modelStorage): super(modelStorage);

  @override
  var findAll = get('/articles').then(find);
  var find = get('/article/{id}');
  var create = post('/article').requiring(title, content);
  var edit = put('/article/{id}').requiring(title, content);
  var remove = delete('/article/{id}');

  var findByTitle = local.constraint(title.value);
  var searchByTitle = local.constraint(title.like);
  var search = searchByTitle.constraint(content.like); // immutable, so we can combine queries
}

@Injectable()
class TableComment extends PartialCachedTable<Comment> {
  var id = key('id');
  var title = column('title');
  var content = column('content');
  var date = column('date', type: constants.date);
  var articleId = column('articleId');

  @override
  Comment fromJson(Map<String, Object> data) => new Comment(data['id'], data['title'], data['content'], data['date']);

  @override
  Map<String, Object> toJson(Comment comment) => {
    'id': comment.id,
    'title': comment.title,
    'content': comment.content,
    'date': comment.date
  };

  TableComment(@indexedDb IModelStorage modelStorage): super(modelStorage, 'comment');

  @override
  var find = get('/article/{articleId}/comment/{commentId}');
  var findByArticle = get('/article/{articleId}/comments').withCache(constants.indexedDb, new Duration(minutes: 5));
  var create = post('/article/{articleId}/comment').requiring(content).optional(title);
  var update = put('/article/{articleId}/comment/{commentId}').requiring(content).optional(title);
  var remove = delete('/article/{articleId}/comment/{commentId}');
}