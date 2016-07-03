// var moment = require('moment');
// var _ = require("underscore");

var FreeBusy = function (start, end, interval) {
    this.times = [];
    this.working_hours = [];
    this.summary = [];
    this.freebusies = [];
    this.emails = [];

    this.start = moment(start);
    this.end = moment(end);
    this.interval = interval;
    this.params = { start: this.start.format(), end: this.end.format() , interval: this.interval };
    
    var duration = moment.duration(this.end.diff(this.start));

    var t = moment(this.start);
    while (t < this.end) {
	var a = moment(t) // for cloning
	this.times.push(a);
	this.summary.push([]);
	t = moment(a);
	t.add(this.interval, 'minutes')
    };
};

FreeBusy.prototype.add = function(freebusy) {
    var f = this;
    var d = freebusy
    if (_.isString(d)) { d = JSON.parse(d) }
    if(d.freebusy.length > f.summary.length) {
	// console.log("truncating freebusy of " + d.email);
    };
    d.freebusy = d.freebusy.substring(0, f.summary.length).split('');
    f.emails.push(d.email);
    f.freebusies.push(d);
    // console.log(d.freebusy.length);
    // console.log(f.summary.length);
    _.each(d.freebusy, function(e, i){
	try { 
	    f.summary[i].push(e)
	} catch (err) {
	    console.log({
		email: d.email,
		i: i,
		error: err,
		freebusy_length: d.freebusy.length,
		summary_length: f.summary.length
	    })
	}
    });
}

FreeBusy.prototype.workingHours = function (start, end, days) {
    var i = this.interval;
    this.working_hours_start = start;
    this.working_hours_end = end;
    
    //------------------------------------------------------------------
    // this should work by setting hour and minutes, and then checking
    // against actual times, not against the hour alone
    // and what about time zone? and personalized working hours?
    //------------------------------------------------------------------
    this.working_hours = _.map(this.times, function(t){
	var w = ((t.hour() >= start)
		 && (moment(t).add(i, 'minutes').hour()) <= end)
    })
};

FreeBusy.prototype.isWorkingTime = function (time) {
    var t = moment(time);
    var start = this.working_hours_start;
    var end = this.working_hours_end;
    var w = ((t.hour() >= start)
	     && (moment(t).add(i, 'minutes').hour()) <= end)
};

FreeBusy.prototype.params = function(){
    return this.params 
}

FreeBusy.prototype.byTime = function() {
    var fb = this;
    // console.log(fb.summary);

    var p = _.map(fb.summary, function(e, i) {
	var p = _.chain(e).filter(function(t){ return t == 0 }).value().length / e.length
	return { time: fb.times[i].format(), availability: p }
    })
    _.each(p, function(e) {
	e.availability_perc = Math.round(e.availability * 100, 0)
	e.time_of_day = moment(e.time).format('HH:mm');
    });
    var days = _.groupBy(p, function(k){
	return moment(k.time).format('YYYY-MM-DD')
    })
    _.each(_.keys(days), function(d){
	days[d] = _.object(
	    _.map(days[d], function(t){ return moment(t.time).format('HH:mm') }),
	    days[d]
	)
    })
    return days;
}

FreeBusy.prototype.availability = function() {
    var f = this;
    var t = moment(arguments[0]);
    var p = _.map(f.summary, function(e) {
	return _.chain(e).filter(function(t){ return t == 0 }).value().length / e.length
    })
    var s =_.object(f.times, p)
    var i = f.slot(t);
    return _.map(f.freebusies, function(e){ return { email: e.email, freebusy: e.freebusy[i] } })
}

FreeBusy.prototype.slot = function() {
    var f = this;
    var t = moment(arguments[0]);
    return _.indexOf(_.map(f.times, function(v){ return v.toString() }), t.toString());
}

FreeBusy.prototype.hours = function() {
    var f = this;
    return _.chain(f.times).map(function(e){ return e.format('HH:mm') }).uniq().sort().value();
}

FreeBusy.prototype.days = function() {
    var f = this;
    return _.chain(f.times).map(function(e){ return e.format('YYYY-MM-DD') }).uniq().value();
}


