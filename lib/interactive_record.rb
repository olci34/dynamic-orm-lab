require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true
        sql = "pragma table_info('#{self.table_name}')"
        table_info = DB[:conn].execute(sql)
        column_names = []
        table_info.each {|row| column_names << row["name"]}
        column_names.compact
    end

    def initialize(options = {})
        options.each do |property, value|
            self.send("#{property}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |col_name|
            values << "'#{self.send(col_name)}'" unless self.send(col_name).nil?
        end
        values.join(", ")
    end

    def save
        sql = <<-SQL
        INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
        VALUES (#{values_for_insert})
        SQL
        DB[:conn].execute(sql)
        self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
        DB[:conn].execute(sql, name)
    end

    def self.find_by (attr)
        col_name = attr.to_a[0][0].to_s
        value = attr.to_a[0][1]
        sql = "SELECT * FROM #{self.table_name} WHERE #{col_name} = '#{value}'"
        DB[:conn].execute(sql)
    end

  
end