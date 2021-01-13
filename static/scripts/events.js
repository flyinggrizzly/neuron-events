// This should match the ID of the directory you are using to contain all event zettels.
// In this case it is `./events/`
var eventRootId = 'events';

/***
* Retrieve an array of all zettel objects in the cache object that are direct folgezettel children of [[events]]
*
* Accepts the object created from JSON.parse(cache.json)
* Returns an Array of zettel objects
*/
var extractEventZettelObjects = cache => {
  var eventCacheElement = cache._neuronCache_graph.adjacencyMap[eventRootId];

  var eventIds = Object.entries(eventCacheElement)
    .filter(([key, value]) => value.includes('Folgezettel'))
    .map(([key, value]) => key);

  var events = eventIds.map(id => cache._neuronCache_graph.vertices[id]);

  return events;
};

/***
* Construct a single link to the parameter zettel object.
*
* Accepts an event zettel object
* Returns a String
*/
var buildEventLinkHtml = eventZettel => {
  var { zettelSlug, zettelTitle } = eventZettel;

  return `
    <li>
      <a href="/${ zettelSlug }.html">${ zettelTitle }</a>
    </li>
  `;
}

/***
* I hate JavaScript's Date. This left-pads a month or date number with a '0' so we can interpolate
* into an ISO8601 string.
*
* Accepts a Number
* Returns a String
*/
var leftPadDateStringComponent = component => {
  var componentString = component.toString();

  if (componentString.length == 1)
    return `0${ componentString }`;
  else
    return componentString;
};

/***
* Declare date elements globally
*/
var today = new Date();
var year = today.getFullYear().toString();
var month = leftPadDateStringComponent(today.getMonth() + 1);
var date = leftPadDateStringComponent(today.getDate());

/***
* Filters an array of zettel objects to those whose ID includes today's date in ISO8601 format,
* prefixed by `event-` (ex: `event-2021-01-01-a-party`).
*
* Accepts an Array of zettel objects
* Returns an Array of zettel objects
*/
var todaysEvents = events => {
  var dateRegexp = new RegExp(`event-${ year }-${ month }-${ date }`);

  return events.filter(event => dateRegexp.test(event.zettelID));
};

/***
* Filters an array of zettel objects to those which recur annually today (where the ID includes the pattern
* `event-yyyy-${currentMonth}-${currentDate}`).
*
* Accepts an Array of zettel objects
* Returns an Array of zettel objects
*/
var annualEvents = events => {
  var dateRegexp = new RegExp(`event-yyyy-(${ month }|mm)-(${ date }|dd)`)

  return events.filter(event => dateRegexp.test(event.zettelID));
};

/***
* Filters an array of zettel objects to those which recur monthly today (where the ID includes the pattern
* `event-yyyy-mm-${currentDate}`).
*
* Accepts an Array of zettel objects
* Returns an Array of zettel objects
*/
var monthlyEvents = events => {
  var dateRegexp = new RegExp(`event-(yyyy|${ year })-mm-(${ date }|dd)`)

  return events.filter(event => dateRegexp.test(event.zettelID));
};

/***
* Filters an array of zettel objects to those which recur daily (where the ID includes the pattern
* `event-yyyy-mm-dd`).
*
* Accepts an Array of zettel objects
* Returns an Array of zettel objects
*/
var dailyEvents = events => {
  var dateRegexp = new RegExp(`event-(${ year }|yyyy)-(${ month }|mm)-dd`)

  return events.filter(event => dateRegexp.test(event.zettelID));
};

/***
* Builds up the HTML headings and lists to insert into the events widget.
*
* Accepts an Array of zettel objects
* Returns a String
*/
var buildEventsHTML = events => {
  var html = [
    "<h1><span class='zettel-link-container cf'><span class='zettel-link'><a href='/events.html'>Events</a></span></span></h1>",
  ]

  if (events.length == 0)
    return html.join('')

  var todays = todaysEvents(events);
  var annuals = annualEvents(events);
  var monthlies = monthlyEvents(events);
  var dailies = dailyEvents(events);

  if (todays.length > 0) {
    html = [
      ...html,
      "<h2>Today's events</h2>",
      "<ul id='todays-events'>",
    ]
    todays.forEach(e => html.push(buildEventLinkHtml(e)));
    html.push('</ul>');
  }

  if (annuals.length > 0) {
    html = [
      ...html,
      "<h2>Events repeating <strong>annually</strong> today</h2>",
      "<ul id='annual-events'>"
    ];
    annuals.forEach(e => html.push(buildEventLinkHtml(e)));
    html.push('</ul>');
  }

  if (monthlies.length > 0) {
    html = [
      ...html,
      "<h2>Events repeating <strong>monthly</strong> today</h2>",
      "<ul id='monthly-events'>"
    ]
    monthlies.forEach(e => html.push(buildEventLinkHtml(e)));
    html.push('</ul>');
  }

  if (dailies.length > 0) {
    html = [
      ...html,
      "<h2>Events repeating <strong>daily</strong> today</h2>",
      "<ul id='daily-events'>"
    ]
    dailies.forEach(e => html.push(buildEventLinkHtml(e)));
    html.push('</ul>');
  }

  return html.join('');
}

/***
* On the homepage of the Neuron project,
* fetches `/cache.json`, and then
* renders the events widget and inserts HTML for the events.
* 
* Accepts no parameters
* Returns undefined
*/
var renderEvents = () => {
  if (document.location.pathname !== '/')
    return

  window.fetch('/cache.json')
    .then(response => response.json())
    .then(cache => {
      var zettelContainer = document.querySelector('#zettel-container');
      var contentContainer = zettelContainer.querySelector('.zettel-view');

      var events = document.createElement('div');
      events.setAttribute('class', 'zettel-view events-container');
      events.setAttribute('style', 'margin-bottom: 20px;')
      var article = document.createElement('article');
      article.setAttribute('class', 'ui raised attached segment zettel-content');
      events.appendChild(article);
      var pandocContainer = document.createElement('div');
      pandocContainer.setAttribute('class', 'pandoc')
      article.appendChild(pandocContainer);

      pandocContainer.innerHTML = buildEventsHTML(extractEventZettelObjects(cache));

      zettelContainer.insertBefore(events, contentContainer);
    });
};

document.addEventListener('DOMContentLoaded', renderEvents);

/***
* Add additional key bindings for navigation
*
* "i" => home/index
* "e" => events
*/
document.addEventListener('keyup', e => {
  if (e.key === 'i')
    document.location.href = '/';
  else if (e.key === 'e')
    document.location.href = `${eventsRootId}.html`;
});
