require 'test_helper'

class TestParser < Minitest::Test

  def test_case_insensitivity
    assert_sql 'SELECT * FROM users WHERE id = 1', 'select * from users where id = 1'
  end

  def test_subquery_in_where_clause
    assert_understands 'SELECT * FROM t1 WHERE id > (SELECT SUM(a) FROM t2)'
  end

  def test_limits
    assert_understands 'SELECT * FROM t1 LIMIT 1'
  end

  def test_order_by_constant
    assert_understands 'SELECT * FROM users ORDER BY 1'
    assert_understands 'SELECT * FROM users ORDER BY 1 ASC'
    assert_understands 'SELECT * FROM users ORDER BY 1 DESC'
  end

  def test_qualified_table
    assert_understands 'SELECT * FROM foo.bar'
  end

  def test_order
    assert_understands 'SELECT * FROM users ORDER BY name'
    assert_understands 'SELECT * FROM users ORDER BY name ASC'
    assert_understands 'SELECT * FROM users ORDER BY name DESC'
  end

  def test_full_outer_join
    assert_understands 'SELECT * FROM t1 FULL OUTER JOIN t2 ON t1.a = t2.a'
    assert_understands 'SELECT * FROM t1 FULL OUTER JOIN t2 ON t1.a = t2.a FULL OUTER JOIN t3 ON t2.a = t3.a'
    assert_understands 'SELECT * FROM t1 FULL OUTER JOIN t2 USING (a)'
    assert_understands 'SELECT * FROM t1 FULL OUTER JOIN t2 USING (a) FULL OUTER JOIN t3 USING (b)'
  end

  def test_full_join
    assert_understands 'SELECT * FROM t1 FULL JOIN t2 ON t1.a = t2.a'
    assert_understands 'SELECT * FROM t1 FULL JOIN t2 ON t1.a = t2.a FULL JOIN t3 ON t2.a = t3.a'
    assert_understands 'SELECT * FROM t1 FULL JOIN t2 USING (a)'
    assert_understands 'SELECT * FROM t1 FULL JOIN t2 USING (a) FULL JOIN t3 USING (b)'
  end

  def test_right_outer_join
    assert_understands 'SELECT * FROM t1 RIGHT OUTER JOIN t2 ON t1.a = t2.a'
    assert_understands 'SELECT * FROM t1 RIGHT OUTER JOIN t2 ON t1.a = t2.a RIGHT OUTER JOIN t3 ON t2.a = t3.a'
    assert_understands 'SELECT * FROM t1 RIGHT OUTER JOIN t2 USING (a)'
    assert_understands 'SELECT * FROM t1 RIGHT OUTER JOIN t2 USING (a) RIGHT OUTER JOIN t3 USING (b)'
  end

  def test_right_join
    assert_understands 'SELECT * FROM t1 RIGHT JOIN t2 ON t1.a = t2.a'
    assert_understands 'SELECT * FROM t1 RIGHT JOIN t2 ON t1.a = t2.a RIGHT JOIN t3 ON t2.a = t3.a'
    assert_understands 'SELECT * FROM t1 RIGHT JOIN t2 USING (a)'
    assert_understands 'SELECT * FROM t1 RIGHT JOIN t2 USING (a) RIGHT JOIN t3 USING (b)'
  end

  def test_left_outer_join
    assert_understands 'SELECT * FROM t1 LEFT OUTER JOIN t2 ON t1.a = t2.a'
    assert_understands 'SELECT * FROM t1 LEFT OUTER JOIN t2 ON t1.a = t2.a LEFT OUTER JOIN t3 ON t2.a = t3.a'
    assert_understands 'SELECT * FROM t1 LEFT OUTER JOIN t2 USING (a)'
    assert_understands 'SELECT * FROM t1 LEFT OUTER JOIN t2 USING (a) LEFT OUTER JOIN t3 USING (b)'
  end

  def test_left_join
    assert_understands 'SELECT * FROM t1 LEFT JOIN t2 ON t1.a = t2.a'
    assert_understands 'SELECT * FROM t1 LEFT JOIN t2 ON t1.a = t2.a LEFT JOIN t3 ON t2.a = t3.a'
    assert_understands 'SELECT * FROM t1 LEFT JOIN t2 USING (a)'
    assert_understands 'SELECT * FROM t1 LEFT JOIN t2 USING (a) LEFT JOIN t3 USING (b)'
  end

  def test_inner_join
    assert_understands 'SELECT * FROM t1 INNER JOIN t2 ON t1.a = t2.a'
    assert_understands 'SELECT * FROM t1 INNER JOIN t2 ON t1.a = t2.a INNER JOIN t3 ON t2.a = t3.a'
    assert_understands 'SELECT * FROM t1 INNER JOIN t2 USING (a)'
    assert_understands 'SELECT * FROM t1 INNER JOIN t2 USING (a) INNER JOIN t3 USING (b)'
  end

  def test_cross_join
    assert_understands 'SELECT * FROM t1 CROSS JOIN t2'
    assert_understands 'SELECT * FROM t1 CROSS JOIN t2 CROSS JOIN t3'
  end

  # The expression
  #   SELECT * FROM t1, t2
  # is just syntactic sugar for
  #   SELECT * FROM t1 CROSS JOIN t2
  def test_cross_join_syntactic_sugar
    assert_sql 'SELECT * FROM t1 CROSS JOIN t2', 'SELECT * FROM t1, t2'
    assert_sql 'SELECT * FROM t1 CROSS JOIN t2 CROSS JOIN t3', 'SELECT * FROM t1, t2, t3'
  end

  def test_having
    assert_understands 'SELECT * FROM users HAVING id = 1'
  end

  def test_group_by
    assert_understands 'SELECT * FROM users GROUP BY name'
    assert_understands 'SELECT * FROM users GROUP BY users.name'
    assert_understands 'SELECT * FROM users GROUP BY name, id'
    assert_understands 'SELECT * FROM users GROUP BY users.name, users.id'
  end

  def test_or
    assert_understands 'SELECT * FROM users WHERE (id = 1 OR age = 18)'
  end

  def test_and
    assert_understands 'SELECT * FROM users WHERE (id = 1 AND age = 18)'
  end

  def test_not
    assert_sql 'SELECT * FROM users WHERE id <> 1', 'SELECT * FROM users WHERE NOT id = 1'
    assert_sql 'SELECT * FROM users WHERE id NOT IN (1, 2, 3)', 'SELECT * FROM users WHERE NOT id IN (1, 2, 3)'
    assert_sql 'SELECT * FROM users WHERE id NOT BETWEEN 1 AND 3', 'SELECT * FROM users WHERE NOT id BETWEEN 1 AND 3'
    assert_sql "SELECT * FROM users WHERE name NOT LIKE 'A%'", "SELECT * FROM users WHERE NOT name LIKE 'A%'"

    # Shouldn't negate subqueries
    assert_understands 'SELECT * FROM users WHERE NOT EXISTS (SELECT id FROM users WHERE id = 1)'
  end

  def test_not_exists
    assert_understands 'SELECT * FROM users WHERE NOT EXISTS (SELECT id FROM users)'
  end

  def test_exists
    assert_understands 'SELECT * FROM users WHERE EXISTS (SELECT id FROM users)'
  end

  def test_is_not_null
    assert_understands 'SELECT * FROM users WHERE deleted_at IS NOT NULL'
  end

  def test_is_null
    assert_understands 'SELECT * FROM users WHERE deleted_at IS NULL'
  end

  def test_not_like
    assert_understands "SELECT * FROM users WHERE name NOT LIKE 'Joe%'"
  end

  def test_like
    assert_understands "SELECT * FROM users WHERE name LIKE 'Joe%'"
  end

  def test_not_in
    assert_understands 'SELECT * FROM users WHERE id NOT IN (1, 2, 3)'
    assert_understands 'SELECT * FROM users WHERE id NOT IN (SELECT id FROM users WHERE age = 18)'
  end

  def test_in
    assert_understands 'SELECT * FROM users WHERE id IN (1, 2, 3)'
    assert_understands 'SELECT * FROM users WHERE id IN (SELECT id FROM users WHERE age = 18)'
  end

  def test_not_between
    assert_understands 'SELECT * FROM users WHERE id NOT BETWEEN 1 AND 3'
  end

  def test_between
    assert_understands 'SELECT * FROM users WHERE id BETWEEN 1 AND 3'
  end

  def test_gte
    assert_understands 'SELECT * FROM users WHERE id >= 1'
  end

  def test_lte
    assert_understands 'SELECT * FROM users WHERE id <= 1'
  end

  def test_gt
    assert_understands 'SELECT * FROM users WHERE id > 1'
  end

  def test_lt
    assert_understands 'SELECT * FROM users WHERE id < 1'
  end

  def test_not_equals
    assert_sql 'SELECT * FROM users WHERE id <> 1', 'SELECT * FROM users WHERE id != 1'
    assert_understands 'SELECT * FROM users WHERE id <> 1'
  end

  def test_equals
    assert_understands 'SELECT * FROM users WHERE id = 1'
  end

  def test_where_clause
    assert_understands 'SELECT * FROM users WHERE 1 = 1'
  end

  def test_sum
    assert_understands 'SELECT SUM(messages_count) FROM users'
  end

  def test_min
    assert_understands 'SELECT MIN(age) FROM users'
  end

  def test_max
    assert_understands 'SELECT MAX(age) FROM users'
  end

  def test_avg
    assert_understands 'SELECT AVG(age) FROM users'
  end

  def test_count
    assert_understands 'SELECT COUNT(*) FROM users'
    assert_understands 'SELECT COUNT(id) FROM users'
  end

  def test_from_clause
    assert_understands 'SELECT 1 FROM users'
    assert_understands 'SELECT id FROM users'
    assert_understands 'SELECT users.id FROM users'
    assert_understands 'SELECT * FROM users'
  end

  def test_select_list
    assert_understands 'SELECT Id FROM Opportunity'
    assert_understands 'SELECT Id, Name, Amount FROM Opportunity'
  end

  def test_as
    assert_understands 'SELECT u.Id FROM User u'
    assert_understands 'SELECT Id OppId FROM Opportunity'
    assert_understands 'SELECT Id, Name OppName FROM Opportunity'
  end

  # SOQL

  def test_select_alias
    assert_understands 'SELECT SUM(Amount) Total FROM Opportunity'
  end

  def test_toLabel
    assert_understands 'SELECT toLabel(StageName) FROM Opportunity'
    assert_understands 'SELECT toLabel(Recordtype.Name) FROM Case'
  end

  def test_using_scope
    assert_understands 'SELECT Id FROM Opportunity USING SCOPE mine'
    assert_understands 'SELECT Id FROM Opportunity USING SCOPE Delegated'
    assert_understands 'SELECT Id FROM Opportunity USING SCOPE Everything'
    assert_understands 'SELECT Id FROM Opportunity USING SCOPE My_Territory'
    assert_understands 'SELECT Id FROM Opportunity USING SCOPE My_Team_Territory'
  end

  def test_order_by_nulls
    assert_understands 'SELECT Id FROM Opportunity ORDER BY StageName DESC NULLS LAST'
    assert_understands 'SELECT Id FROM Opportunity ORDER BY StageName DESC NULLS LAST, Id ASC NULLS FIRST'
  end

  # TODO
  # def test_with_filters
  #   assert_understands "SELECT Id FROM UserProfileFeed WITH UserId='005D0000001AamR' ORDER BY CreatedDate DESC, Id DESC LIMIT 20"
  # end
  #
  # def test_with_data_category_filters
  #   assert_understands "SELECT Title FROM KnowledgeArticleVersion WHERE PublishStatus='online' WITH DATA CATEGORY Geography__c ABOVE usa__c"
  #   assert_understands "SELECT Title FROM Question WHERE LastReplyDate > 2005-10-08T01:02:03Z WITH DATA CATEGORY Geography__c AT (usa__c, uk__c)"
  #   assert_understands "SELECT UrlName FROM KnowledgeArticleVersion WHERE PublishStatus='draft' WITH DATA CATEGORY Geography__c AT usa__c AND Product__c ABOVE_OR_BELOW mobile_phones__c"
  # end

  def test_soql_queries
    assert_understands 'SELECT Name, Account.Name, toLabel(StageName), CloseDate, Amount, Fiscal, Id, RecordTypeId, CreatedDate, LastModifiedDate, SystemModstamp FROM Opportunity USING SCOPE mine WHERE Amount > 10000 ORDER BY StageName DESC NULLS LAST, Id ASC NULLS FIRST'

	# Parentheses are added to where clause
    assert_sql 'SELECT Name, toLabel(StageName) FROM Opportunity WHERE (IsClosed = false AND CloseDate = THIS_MONTH) ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST', 'SELECT Name, toLabel(StageName) FROM Opportunity WHERE IsClosed = false AND CloseDate = THIS_MONTH ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST'

  end

  private

  def assert_sql(expected, given)
    assert_equal expected, SQLParser::Parser.parse(given).to_sql
  end

  def assert_understands(sql)
    assert_sql(sql, sql)
  end
end
