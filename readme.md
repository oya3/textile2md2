redmine の textile 形式 を markdown 形式にそれっぽく変換する
以下、手順

``` bash
# redmine gemfile に padoc 追加
$ sudo apt install pandoc
# textile2md2.rake を  lib/tasks/textile2md2.rake に配置しておく
$ emacs Gemfile
...
gem 'pandoc-ruby'
...
$ bundle i

# 旧DBを削除(dbuser:redmine, dbname:redmine50を対象にする）
$ mysql -u root -p
# DB 確認
MariaDB [(none)]> show databases;

# redmine50 削除
MariaDB [(none)]> drop database redmine50;
Query OK, 71 rows affected (0.522 sec)

# redmine50 再作成
MariaDB [(none)]> CREATE DATABASE redmine50 default CHARACTER SET utf8mb4;
Query OK, 1 row affected (0.001 sec)
# redmine ユーザ割当
MariaDB [(none)]> GRANT ALL PRIVILEGES ON redmine50.* TO 'redmine'@'localhost';
Query OK, 0 rows affected (0.005 sec)
# 反映
MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> exit;
Bye

# バックアップしたdbdumpを書き戻す
$ sudo mysql -u redmine -p redmine50 < redmine50_msqldump.txt

# 鍵生成
$ bundle exec rake generate_secret_token
# 全体DB更新
$ bundle exec rake db:migrate RAILS_ENV=production
# クリーンナップ
$ bundle exec rake tmp:cache:clear RAILS_ENV=production 

# textile から markdown に変換
$ bundle exec rake textile2md2:execute RAILS_ENV=production

# redmine 再起動
$ sudo systemctl restart apache2
```
