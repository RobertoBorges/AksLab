var createError = require("http-errors");
var express = require("express");
var path = require("path");
var cookieParser = require("cookie-parser");
var logger = require("morgan");
var path = require("path");
var logger = require("morgan");
var Handlebars = require("handlebars");
var exphbs = require("express-handlebars");
var session = require("express-session");
var flash = require("express-flash");
var favicon = require("serve-favicon");
var passport = require("./config/passport.config");
var i18n = require("i18n");
const promBundle = require("express-prom-bundle");
const metricsMiddleware = promBundle({includeMethod: true});

var app = express();

// Register the metrics middleware using the express-prom-bundle
app.use(metricsMiddleware);

// Configure i18n
i18n.configure({
  objectNotation: true,
  locales: ["en", "es"],
  directory: path.join(__dirname, "locales"),
});

// Register i18n as a middleware
app.use(i18n.init);

// Register the i18n helper with Handlebars
var hbs = exphbs.create({
  extname: ".hbs",
  defaultLayout: "main",
  layoutsDir: path.join(__dirname, "views/layouts"),
  partialsDir: path.join(__dirname, "views/partials"),
  helpers: {
    i18n: function (str) {
      return new Handlebars.SafeString(i18n.__(str));
    },
  },
});

// view engine setup
app.engine("hbs", hbs.engine);
app.set("views", path.join(__dirname, "views"));
app.set("view engine", "hbs");

app.use(favicon(__dirname + "/public/assets/favicon.ico"));
app.use(express.static(path.join(__dirname, "public")));

app.use(cookieParser());
app.use(logger("dev"));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(flash());
app.use(session({ secret: "secret", ressave: true, saveUninitialized: true }));
app.use(passport.initialize());
app.use(passport.session());
app.use(express.static(path.join(__dirname, "public")));

app.use("/", require("./routes"));

// catch 404 and forward to error handler
app.use(function (req, res, next) {
  next(createError(404));
});

// error handler
app.use(function (err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get("env") === "development" ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render("error");
});

module.exports = app;
