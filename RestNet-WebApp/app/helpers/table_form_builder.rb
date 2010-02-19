class TableFormBuilder < ActionView::Helpers::FormBuilder
  
  def table_form_for(object_name, *args, &proc)
    # @template.content_tag("table",super)
    #super
  end
  
  def self.create_tabled_field(method_name)
    define_method(method_name) do |label, *args|
      #label_content = label(label)
      
      the_object_name = I18n.t(label, :default => label, :scope => [:activerecord, :attributes, object_name], :count => 1)
      label_content = @template.content_tag("label", the_object_name)
      content_error = error_message_on(label,["#{the_object_name} "])
      content = @template.content_tag("tr",
      @template.content_tag("td",label_content)+@template.content_tag("td",super+content_error))      
      content    
    end
  end
  field_helpers.each do |name|
    create_tabled_field(name)
  end
  #create_tabled_field(:password_field)
  #create_tabled_field(:text_field)
  #  def password_field(label, *args) 
  #    label_content = label(label)
  #    the_object_name = I18n.t(label, :default => label, :scope => [:activerecord, :attributes, object_name], :count => 1)
  #    content_error = error_message_on(label,["#{the_object_name} "])
  #    content = @template.content_tag("tr",
  #    @template.content_tag("td",label_content)+@template.content_tag("td",super+content_error))
  #    
  #    content    
  #  end
  #  def text_field(label, *args)
  #    
  #    label_content = label(label)
  #    the_object_name = I18n.t(label, :default => label, :scope => [:activerecord, :attributes, object_name], :count => 1)
  #    content_error = error_message_on(label,["#{the_object_name} "])
  #    content = @template.content_tag("tr",
  #    @template.content_tag("td",label_content)+@template.content_tag("td",super+content_error))
  #    
  #    
  #    content
  #  end
  #  
  
  
end