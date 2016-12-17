function exportTableToCSV($table, filename) {
    var rows = [];
    $table.children('tbody').children('tr').each(function(c, r){
	var row = [];
	$(r).find('td').each(function(e, i){
	    if ($(i).children().size() === 0) {
		row.push($(i).html().replace('"', '""'));
	    }
	});
	rows.push(row)
    });
    var colDelim = '","'; var rowDelim = '"\r\n"';
    
    rows = _.map(rows, function(i) { return i.join(colDelim)  });
    console.log(rows.join(rowDelim));
    var csvData = 'data:application/csv;charset=utf-8,' + '"' + encodeURIComponent(rows.join(rowDelim)) + '"';

    
    if (window.navigator.msSaveOrOpenBlob) {
        var blob = new Blob([decodeURIComponent(encodeURI(csvData))], {
            type: "text/csv;charset=utf-8;"
        });
        navigator.msSaveBlob(blob, filename);
    } else {
        $(this)
            .attr({
                'download': filename
                ,'href': csvData
                //,'target' : '_blank' //if you want it to open in a new window
            });
    }
}


// This must be a hyperlink
