<header>
  <h1>{{ title }}</h1>
  <div class="user">
    <ng-container *ngIf="auth.isLoggedIn; else loginButton">
      <span>{{ auth.username }} <small>({{ auth.roles.join(', ') }})</small></span>
      <button type="button" (click)="auth.logout()">Sign out</button>
    </ng-container>
    <ng-template #loginButton>
      <button type="button" (click)="auth.login()">Sign in</button>
    </ng-template>
  </div>
</header>

<main *ngIf="auth.isLoggedIn; else anonymous">
  <nav>
    <button *ngFor="let tab of resources" [class.active]="tab === current" (click)="select(tab)">
      {{ tab.label }}
    </button>
  </nav>

  <form (ngSubmit)="add()">
    <input name="newName" [(ngModel)]="newName" placeholder="Name" required>
    <button type="submit">Add</button>
  </form>

  <p class="error" *ngIf="error">{{ error }}</p>

  <ul>
    <li *ngFor="let item of items">
      <span>{{ item.name }}</span>
      <small>{{ item.createdAt | date: 'short' }}</small>
    </li>
  </ul>
</main>

<ng-template #anonymous>
  <main>
    <p *ngIf="!auth.unavailable">Please sign in to access the application.</p>
    <p class="error" *ngIf="auth.unavailable">The authentication service is unavailable. Please try again later.</p>
  </main>
</ng-template>
