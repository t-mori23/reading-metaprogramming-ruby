# 次の仕様を満たす、SimpleModelモジュールを作成してください
#
# 1. include されたクラスがattr_accessorを使用すると、以下の追加動作を行う
#   1. 作成したアクセサのreaderメソッドは、通常通りの動作を行う
#   2. 作成したアクセサのwriterメソッドは、通常に加え以下の動作を行う
#     1. 何らかの方法で、writerメソッドを利用した値の書き込み履歴を記憶する
#     2. いずれかのwriterメソッド経由で更新をした履歴がある場合、 `true` を返すメソッド `changed?` を作成する
#     3. 個別のwriterメソッド経由で更新した履歴を取得できるメソッド、 `ATTR_changed?` を作成する
#       1. 例として、`attr_accessor :name, :desc`　とした時、このオブジェクトに対して `obj.name = 'hoge` という操作を行ったとする
#       2. `obj.name_changed?` は `true` を返すが、 `obj.desc_changed?` は `false` を返す
#       3. 参考として、この時 `obj.changed?` は `true` を返す
# 2. initializeメソッドはハッシュを受け取り、attr_accessorで作成したアトリビュートと同名のキーがあれば、自動でインスタンス変数に記録する
#   1. ただし、この動作をwriterメソッドの履歴に残してはいけない
# 3. 履歴がある場合、すべての操作履歴を放棄し、値も初期状態に戻す `restore!` メソッドを作成する

module SimpleModel
  def initialize(**hash)
    hash.each do |key, value|
      if self.class.instance_methods.include?("#{key}=".to_sym)
        instance_variable_set("@#{key}", value) 
        instance_variable_set("@#{key}_initial_value", value) 
      end
    end
  end

  def self.included(base)
    base.instance_eval do
      def self.attr_accessor(*keys)
        instance_variable_set(:@attr_accessor_keys, keys)

        keys.each do |key|
          attr_reader key

          define_method("#{key}=") do |value|
            history = instance_variable_get("@#{key}_history") || []

            instance_variable_set("@#{key}_history", history.push(value))
            instance_variable_set("@#{key}", value)
          end

          define_method("#{key}_changed?") do
            return false if instance_variable_get("@#{key}_history").nil?

            !instance_variable_get("@#{key}_history").empty?
          end
        end
      end
    end
  end

  def changed?
    changed_method_symbols = self.class.instance_methods.select { |v| v.to_s.end_with?("_changed?") }
    changed_method_symbols.any? { |h| send(h) }
  end

  def restore!
    keys = self.class.instance_variable_get(:@attr_accessor_keys)

    return if keys.nil?

    keys.each do |key|
      instance_variable_set("@#{key}_history", [])
      instance_variable_set("@#{key}", instance_variable_get("@#{key}_initial_value"))
    end
  end
end
