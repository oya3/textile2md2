# coding: utf-8
require 'pandoc-ruby' # https://github.com/alphabetum/pandoc-ruby

namespace :textile2md2 do
  desc "Convert Textile to Markdown"
  task :execute => :environment do
    puts "textile2md2"
    Textile2md2.update_content(WikiContent, :text)
    Textile2md2.update_content(Issue, :description)
    Textile2md2.update_content(Journal, :notes)
  end
end

class Textile2md2

  def self.before_remake(pan)
    # pan.gsub!(/^\n([#*]+) +(.+)$/) do |m|
    #   m1 = $1
    #   m2 = $2
    #   result = "\n  \n" + m1 + ' ' + m2
    #   result
    # end
    pan.gsub!(/<pre><code class="\w+">/,'<pre><code>')  # pandoc が応答なくなるので削除    
    pan.gsub!(/^ *((?:\*#|\*\*#|#\*|##\*)[*#]*) +(.+)$/) do |m|
      m1 = $1
      m2 = $2
      count = m1.length()
      indent = '    ' * count
      val = m1[count-1] == "#" ? "1." : "-"
      result = indent + val + ' ' + m2
      # puts "#:" + m
      # puts ">:" + result
      result
    end
    
    # # テーブルの結合や変換不可のパラメータを破棄
    # pan.gsub!(/\|([\/\\]\d)+(\=\{\s*background\s*:\s*.+?\s*\})*\. /, '| ')
    # pan.gsub!(/\|(.*\|)+\s*$/) do |m|
    #   m1 = $1
    #   '|' + m1.gsub(/<br>/,'') + "\n"
    # end
    
    # Move the class from <code> to <pre> so pandoc can generate a code block with correct language
    pan.gsub!(/(<pre)(><code)( +class="[^"]*")(>)/, '\\1\\3\\2\\4')
    
    # Remove the <code> directly inside <pre>, because pandoc would incorrectly preserve it
    pan.gsub!(/(<pre[^>]*>) *<code>/, '\\1')
    pan.gsub!(/<\/code> *(<\/pre>)/, '\\1')
    
    # Inject a class in all <pre> that do not have a blank line before them
    # This is to force pandoc to use fenced code block (```) otherwise it would
    # use indented code block and would very likely need to insert an empty HTML
    # comment "<!-- -->" (see http://pandoc.org/README.html#ending-a-list)
    # which are unfortunately not supported by Redmine (see http://www.redmine.org/issues/20497)
    tag_fenced_code_block = 'force-pandoc-to-ouput-fenced-code-block'
    pan.gsub!(/([^\n]<pre)(>)/, "\\1 class=\"#{tag_fenced_code_block}\"\\2")
    
    # Force <pre> to have a blank line before them
    # Without this fix, a list of items containing <pre> would not be interpreted as a list at all.
    pan.gsub!(/([^\n])(<pre)/, "\\1\n\n\\2")
    # ----------------------------------------------------------------------------------
    # -                                      特別                                      -
    # 単語のスペースを無理やりマジックコード直しておく
    pan.gsub!(/([a-zA-Z]) ([a-zA-Z])/, '\\1＠SAPCE＠\\2')
    # テーブルの前行が文字列の場合、マジックコードを追加して空行にしておく
    pan.gsub!(/([^\|])$(\s*\|)/,"\\1＠TableContinue＠\n\n\\2")
    # pan.gsub!(/([^\|])\n(\s*\|)/) do |m|
    #   $1 + "＠TableContinue＠\n\n" + $2
    # end
    pan
  end
  
  def self.after_remake(pan)
    # 無駄コメント削除
    # pan.gsub!(/^\<\!-- --\>$/,'')
    # リスト項目
    # '\\*\\#\\* test'.sub(/((?:\\*|\\#)+) (.+)/, '\1 \2')
    pan.gsub!(/\\\[/,'[')
    pan.gsub!(/\\\]/,']')
    # 見出し１を#に変換
    pan.gsub!(/^(.+)\n={3,}$/) do |m|
      '# ' + $1 + "\n"
    end
    # 見出し２を##に変換
    pan.gsub!(/^(.+)\n-{3,}$/) do |m|
      '## ' + $1 + "\n"
    end

    # (1.|-)改行 のケースを救う
    pan.gsub!(/^(\s*)(\d+\.|-)\n\s*(.+)$/) do |m|
      $1 + $2 + ' ' + $3
    end

    # - #0000改行 のケースを救う
    pan.gsub!(/^(\s*)-\s+(\\#\d+)\s*\n\s*(.+)$/) do |m|
      $1 + '- ' + $2 + ' ' + $3
    end

    # ----------------------------------------------------------------------------------
    # -                                      特別                                      -
    # 単語のスペースをマジックコードからスペースに戻す
    pan.gsub!(/([a-zA-Z])＠SAPCE＠([a-zA-Z])/, '\\1 \\2')

    # テーブルの前行が文字列の場合のマジックコードを改行に戻す
    pan.gsub!(/＠TableContinue＠\n\n/, "\n")

    # # 複数行の色替え変換(リスト表示に対応できないので却下）
    # pan.gsub!(/%\{\s*color\s*:\s*(red)\s*\}(.+?)%/m) do |m|
    #   "<div style=\"color:" + $1 + ";\">\n" + $2 + "\n" + "</div>\n"
    # end

    # pan.gsub!(/^ *((?:\\\*|\\#)+) +(.+)$/) do |m|
    #   # puts m
    #   m1 = $1
    #   m2 = $2
    #   count = m1.length() / 2 - 1
    #   indent = '    ' * count
    #   val = m1[m1.length() - 1] == "#" ? "1." : "-"
    #   indent + val + ' ' + m2
    # end
    # pan.gsub!(/^ *((?:\\\*|\\#)+)\n *(.+)$/) do |m|
    #   # puts m
    #   m1 = $1
    #   m2 = $2
    #   count = m1.length() / 2 - 1
    #   indent = '    ' * count
    #   val = m1[m1.length() - 1] == "#" ? "1." : "-"
    #   indent + val + ' ' + m2
    # end
    pan
  end

  def self.remake(pan)
    pan = self.before_remake(pan)
    converter = PandocRuby.new(pan, :from => :textile, :to => :markdown_mmd)
    # converter = PandocRuby.new(pan, :from => :textile, :to => :commonmark)
    # converter = PandocRuby.new(pan, :from => :textile, :to => :commonmark_x)
    pan = converter.convert
    pan = self.after_remake(pan)
    pan
  end
  
  def self.update_content(model, attrbute)
    total = model.count
    step = total / 10
    puts "  #{model}.#{attrbute} : #{total}"
    model.all.each_with_index do |rec, ix|
      n = ix + 1
      puts sprintf("%8d", n)   if n % step == 0
      rec.with_lock do
        if rec[attrbute]
          pan = rec[attrbute]
          puts "################ START ###################\n"
          puts "#{pan.slice(0,pan.index("\n")||0)}"
          # if pan =~ / ＯＳＫ宛完了確認書作成/
          #   puts pan
          #   exit
          # end
          pan = self.remake(pan)
          rec[attrbute] = pan
          rec.save!

          # # オプティミスティックロックを導入
          # rec.with_lock do
          #   rec.reload # 最新のデータを読み込む
          #   rec[attrbute] = pan
          #   rec.save!
          # end
        end
        puts "################ END   ###################\n"
      end
    end
  end
end
