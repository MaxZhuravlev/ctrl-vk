var App;

App = (function() {

  function App() {
    console.log('app start');
  }

  return App;

})();

window.onload = function() {
  return window.app = new App;
};
