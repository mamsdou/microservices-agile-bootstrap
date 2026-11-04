<header>
  <h1>{{ title }}</h1>
  <div class="user">
    <ng-container *ngIf="auth.isLoggedIn; else loginButton">
      <span>{{ auth.username }} <small>({{ auth.roles.join(', ') }})</small></span>
      <button type="button" (click)="auth.logout()">Deconnexion</button>
    </ng-container>
    <ng-template #loginButton>
      <button type="button" (click)="auth.login()">Se connecter</button>
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
    <input name="newName" [(ngModel)]="newName" placeholder="Nom" required>
    <button type="submit">Ajouter</button>
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
    <p *ngIf="!auth.unavailable">Veuillez vous connecter pour acceder a l'application.</p>
    <p class="error" *ngIf="auth.unavailable">Le service d'authentification est indisponible. Reessayez plus tard.</p>
  </main>
</ng-template>
