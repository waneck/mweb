// github api example:

function getBase(ctx) return
{
	issues: new IssueHandler(ctx),
	gists: new GistHandler(ctx),
	notifications: new NotificationHandler(ctx),
}

{
	any: getBase(ctx),
	users: function (u:String, d:SubDispatcher)
		return d.sub(getBase(ctx.withUser(u))), //sera que nao faz mais sentido retornar o dispatcher?
	repos: @:repos function (u:String, repo:String, d:SubDispatcher)
		return d.sub(getBase(ctx.withUserRepo(u,repo)))
}
