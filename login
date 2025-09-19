// src/app/app-routing.module.ts
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { UsersComponent } from './users/users.component';
import { AuthGuard } from './auth/auth.guard';

const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'dashboard', component: DashboardComponent, canActivate: [AuthGuard] },
  { path: 'users', component: UsersComponent, canActivate: [AuthGuard] },
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: '**', redirectTo: 'login' }
];

@NgModule({
  imports: [ RouterModule.forRoot(routes) ],
  exports: [ RouterModule ]
})
export class AppRoutingModule {}



// src/app/auth/auth.service.ts
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { tap, map, catchError } from 'rxjs/operators';

@Injectable({ providedIn: 'root' })
export class AuthService {
  // BehaviorSubject so components can subscribe and get current value immediately
  private authSubject = new BehaviorSubject<boolean>(this.hasValidToken());
  public authStatus$ = this.authSubject.asObservable();

  constructor(private http: HttpClient) {}

  // Call backend, expect { token: '...' } on success
  login(username: string, password: string): Observable<boolean> {
    return this.http.post<{ token: string }>('/api/auth/login', { username, password }).pipe(
      tap(resp => {
        // store token and update auth state
        localStorage.setItem('token', resp.token);
        this.authSubject.next(true);
      }),
      map(() => true),
      catchError(err => {
        console.error('Login failed', err);
        return of(false);
      })
    );
  }

  logout() {
    localStorage.removeItem('token');
    this.authSubject.next(false);
  }

  getToken(): string | null {
    return localStorage.getItem('token');
  }

  isLoggedIn(): boolean {
    return this.hasValidToken();
  }

  // helpers
  private hasValidToken(): boolean {
    const token = this.getToken();
    if (!token) return false;
    try {
      const payload = this.parseJwt(token);
      if (!payload || !payload.exp) return false;
      return (Date.now() / 1000) < payload.exp;
    } catch {
      return false;
    }
  }

  private parseJwt(token: string): any {
    // decode base64url
    try {
      const parts = token.split('.');
      if (parts.length !== 3) throw new Error('JWT malformed');
      const base64Url = parts[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(atob(base64).split('').map(c =>
        '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)
      ).join(''));
      return JSON.parse(jsonPayload);
    } catch (e) {
      throw e;
    }
  }
}



// src/app/auth/auth.guard.ts
import { Injectable } from '@angular/core';
import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router, UrlTree } from '@angular/router';
import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class AuthGuard implements CanActivate {
  constructor(private auth: AuthService, private router: Router) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean | UrlTree {
    if (this.auth.isLoggedIn()) {
      return true;
    }
    // Redirect to login if not authenticated
    return this.router.createUrlTree(['/login']);
  }
}


<!-- src/app/login/login.component.html -->
<form (ngSubmit)="onLogin()" #loginForm="ngForm" novalidate>
  <div>
    <label>Username</label>
    <input name="username" [(ngModel)]="username" required />
  </div>

  <div>
    <label>Password</label>
    <input name="password" type="password" [(ngModel)]="password" required />
  </div>

  <button type="submit" [disabled]="loginForm.invalid">Login</button>

  <div *ngIf="error" style="color:red; margin-top:8px;">{{ error }}</div>
</form>


// src/app/login/login.component.ts
import { Component } from '@angular/core';
import { AuthService } from '../auth/auth.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html'
})
export class LoginComponent {
  username = '';
  password = '';
  error = '';

  constructor(private auth: AuthService, private router: Router) {}

  onLogin() {
    this.error = '';
    this.auth.login(this.username, this.password).subscribe(success => {
      if (success) {
        // Navigate to dashboard after successful login
        this.router.navigate(['/dashboard']);
      } else {
        this.error = 'Invalid username or password';
      }
    });
  }
}




// src/app/auth/auth.interceptor.ts
import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from './auth.service';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private auth: AuthService) {}

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = this.auth.getToken();
    if (token) {
      const cloned = req.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`
        }
      });
      return next.handle(cloned);
    }
    return next.handle(req);
  }
}




// src/app/app.module.ts
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { LoginComponent } from './login/login.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { UsersComponent } from './users/users.component';

import { AuthInterceptor } from './auth/auth.interceptor';

@NgModule({
  declarations: [
    AppComponent,
    LoginComponent,
    DashboardComponent,
    UsersComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    FormsModule,        // needed for [(ngModel)]
    HttpClientModule    // needed for HttpClient
  ],
  providers: [
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true }
  ],
  bootstrap: [AppComponent]
})
export class AppModule {}




<nav>
  <a routerLink="/dashboard" *ngIf="(auth.authStatus$ | async)">Dashboard</a>
  <a routerLink="/login" *ngIf="!(auth.authStatus$ | async)">Login</a>
  <button *ngIf="(auth.authStatus$ | async)" (click)="logout()">Logout</button>
</nav>







constructor(public auth: AuthService, private router: Router) {}
logout() {
  this.auth.logout();
  this.router.navigate(['/login']);
}