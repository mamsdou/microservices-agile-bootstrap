import { HttpErrorResponse } from '@angular/common/http';
import { Component, OnInit } from '@angular/core';

import { ApiService, Item } from './api.service';
import { AuthService } from './auth.service';

interface ResourceTab {
  label: string;
  path: string;
}

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
})
export class AppComponent implements OnInit {
  readonly title = '@@PROJECT_TITLE@@';
  readonly resources: ResourceTab[] = @@RESOURCES_TS@@;

  current: ResourceTab = this.resources[0];
  items: Item[] = [];
  newName = '';
  error = '';

  constructor(private readonly api: ApiService, readonly auth: AuthService) {}

  ngOnInit(): void {
    if (this.auth.isLoggedIn) {
      this.load();
    }
  }

  select(tab: ResourceTab): void {
    this.current = tab;
    this.load();
  }

  load(): void {
    this.api.list(this.current.path).subscribe({
      next: (items) => {
        this.items = items;
        this.error = '';
      },
      error: (err: HttpErrorResponse) => {
        this.items = [];
        this.error = this.message(err, 'Could not load the data (is the gateway running?).');
      },
    });
  }

  add(): void {
    const name = this.newName.trim();
    if (!name) {
      return;
    }
    this.api.create(this.current.path, name).subscribe({
      next: () => {
        this.newName = '';
        this.load();
      },
      error: (err: HttpErrorResponse) => (this.error = this.message(err, 'Could not create the item.')),
    });
  }

  private message(err: HttpErrorResponse, fallback: string): string {
    if (err.status === 401) {
      return 'Session expired: please sign in again.';
    }
    if (err.status === 403) {
      return 'Access denied: your role does not allow this action.';
    }
    return fallback;
  }
}
