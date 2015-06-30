class DefChildrenCountToPost < ActiveRecord::Migration
  def up
    sql = '
          create index id_idx on discussion_posts(id);
          create index parent_id_idx on discussion_posts(parent_id);

          UPDATE discussion_posts SET
            children_count=COALESCE((select count(children.id) from discussion_posts dp JOIN discussion_posts children ON children.parent_id = dp.id WHERE dp.id = discussion_posts.id AND children.parent_id IS NOT NULL GROUP BY dp.id LIMIT 1),0);
          '

    Post.connection.execute(sql)
  end
end
