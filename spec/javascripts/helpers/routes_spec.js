describe('Routes', function() {
  var Routes = window.shared.Routes;

  describe('#studentProfile', function() {
    it('returns URLs with encoded query string', function() {
      expect(Routes.studentProfile(3)).toEqual('/students/3');
      expect(Routes.studentProfile(3, {foo: 'value is bar'})).toEqual('/students/3?foo=value+is+bar');
    });
  });
});