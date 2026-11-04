import { APP_INITIALIZER, NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http';
import { BrowserModule } from '@angular/platform-browser';
import { OAuthModule } from 'angular-oauth2-oidc';

import { AppComponent } from './app.component';
import { AuthService } from './auth.service';

@NgModule({
  declarations: [AppComponent],
  imports: [
    BrowserModule,
    HttpClientModule,
    FormsModule,
    // Ajoute automatiquement "Authorization: Bearer <token>" aux appels dont l'URL commence par /api.
    OAuthModule.forRoot({ resourceServer: { allowedUrls: ['/api'], sendAccessToken: true } }),
  ],
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: (auth: AuthService) => () => auth.init(),
      deps: [AuthService],
      multi: true,
    },
  ],
  bootstrap: [AppComponent],
})
export class AppModule {}
