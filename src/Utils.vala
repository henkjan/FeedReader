public class FeedReader.Utils : GLib.Object {


	public static void generatePreviews(ref GLib.List<article> articles)
	{
		foreach(var article in articles)
		{
			if(!dataBase.preview_empty(article.getArticleID()))
			{
				article.setPreview(dataBase.read_preview(article.getArticleID()));
			}
			else if(article.getHTML() != "")
			{
				string filename = GLib.Environment.get_tmp_dir() + "/" + "articleHtml.XXXXXX";
				int outputfd = GLib.FileUtils.mkstemp(filename);
				try{
					GLib.FileUtils.set_contents(filename, article.getHTML());
				}
				catch(GLib.FileError e){
					logger.print(LogMessage.ERROR, "error writing html to tmp file - %s".printf(e.message));
				}
				GLib.FileUtils.close(outputfd);

				string output = "";
				string[] spawn_args = {"html2text", "-utf8", "-nobs", "-style", "pretty", filename};
				try{
					GLib.Process.spawn_sync(null, spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, out output, null, null);
				}
				catch(GLib.SpawnError e){
					logger.print(LogMessage.ERROR, "html2text: %s".printf(e.message));
				}

				string prefix = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>";
				if(output.has_prefix(prefix))
					output = output.slice(prefix.length, output.length);

				int length = 300;
				if(output.length < 300)
					length = output.length;

				output = output.replace("\n"," ");
				output = output.replace("_"," ");
				output = output.slice(0, length);
				output = output.slice(0, output.last_index_of(" "));
				output = output.chug();

				article.setPreview(output);
			}
			else
			{
				article.setPreview(_("No Preview Available"));
			}
		}
	}


	public static void checkHTML(ref GLib.List<article> articles)
	{
		foreach(var article in articles)
		{
			string modified_html = _("No Text available for this article :(");
			if(article.getHTML() != "")
			{
				modified_html = article.getHTML().replace("src=\"//","src=\"http://");
			}

			article.setHTML(modified_html);
		}
	}


	public static string[] getDefaultExpandedCategories()
	{
		string[] e = {};
		e += "Categories";
		if(settings_general.get_enum("account-type") == Backend.TTRSS)
			e += "Labels";
		else
			e += "Tags";

		return e;
	}

}
