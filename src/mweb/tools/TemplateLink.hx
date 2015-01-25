package mweb.tools;

/**
	A TemplateLink represents the link of a Template with data type `T` to the actual data.
	It can be used as a way to avoid returning strings on the Dispatcher, which allows one to reuse a method that binds
	a template to use another compatible template, or even serialize the data itself.
 **/
class TemplateLink<T>
{
	public var template(default,null):Template<T>;
	public var data(default,null):T;

	public function new(template,data)
	{
		this.template = template;
		this.data = data;
	}

	/**
		Executes the template's contents
	 **/
	public function execute():String
		return template.execute(data);

	public function toString()
		return execute();
}
